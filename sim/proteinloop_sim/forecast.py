"""Deterministic anomaly forecast for near-term collapse risk."""

from __future__ import annotations

from dataclasses import dataclass

from .policies import naive_policy
from .simulator import EcosystemSimulator
from .state import EcosystemState
from .verifier import SafetyVerifier


@dataclass(frozen=True)
class AnomalyForecast:
    horizon_days: int
    risk_level: str
    collapsed: bool
    first_critical_day: int | None
    max_ammonia_mg_l: float
    min_oxygen_mg_l: float
    recommendation: str
    timeline: tuple[dict[str, object], ...]

    def to_dict(self) -> dict[str, object]:
        return {
            "horizon_days": self.horizon_days,
            "risk_level": self.risk_level,
            "collapsed": self.collapsed,
            "first_critical_day": self.first_critical_day,
            "max_ammonia_mg_l": self.max_ammonia_mg_l,
            "min_oxygen_mg_l": self.min_oxygen_mg_l,
            "recommendation": self.recommendation,
            "timeline": list(self.timeline),
        }


def forecast_anomaly(
    state: EcosystemState,
    horizon_days: int = 5,
    verifier: SafetyVerifier | None = None,
) -> AnomalyForecast:
    """Forecast routine-operation risk without mutating the live state."""

    verifier = verifier or SafetyVerifier()
    sim = EcosystemSimulator(state=state.clone(), verifier=verifier)
    timeline: list[dict[str, object]] = []
    first_critical_day: int | None = None
    max_ammonia = state.ammonia_mg_l
    min_oxygen = state.dissolved_oxygen_mg_l

    for _ in range(horizon_days):
        result = sim.step(naive_policy(sim.state), validate=False)
        current = result.state
        max_ammonia = max(max_ammonia, current.ammonia_mg_l)
        min_oxygen = min(min_oxygen, current.dissolved_oxygen_mg_l)

        critical = (
            current.collapsed
            or current.ammonia_mg_l >= verifier.ammonia_critical_mg_l
            or current.dissolved_oxygen_mg_l <= verifier.oxygen_critical_mg_l
        )
        if critical and first_critical_day is None:
            first_critical_day = current.day

        timeline.append(
            {
                "day": current.day,
                "ammonia_mg_l": round(current.ammonia_mg_l, 3),
                "dissolved_oxygen_mg_l": round(current.dissolved_oxygen_mg_l, 3),
                "collapsed": current.collapsed,
                "critical": critical,
            }
        )

        if current.collapsed:
            break

    collapsed = sim.state.collapsed
    risk_level = _risk_level(max_ammonia, min_oxygen, collapsed, verifier)

    return AnomalyForecast(
        horizon_days=horizon_days,
        risk_level=risk_level,
        collapsed=collapsed,
        first_critical_day=first_critical_day,
        max_ammonia_mg_l=round(max_ammonia, 3),
        min_oxygen_mg_l=round(min_oxygen, 3),
        recommendation=_recommendation(risk_level),
        timeline=tuple(timeline),
    )


def _risk_level(
    max_ammonia: float,
    min_oxygen: float,
    collapsed: bool,
    verifier: SafetyVerifier,
) -> str:
    if (
        collapsed
        or max_ammonia >= verifier.ammonia_critical_mg_l
        or min_oxygen <= verifier.oxygen_critical_mg_l
    ):
        return "critical"

    if (
        max_ammonia >= verifier.ammonia_warning_mg_l
        or min_oxygen < verifier.oxygen_warning_mg_l
    ):
        return "warning"

    return "stable"


def _recommendation(risk_level: str) -> str:
    if risk_level == "critical":
        return "Pause feeding, maximize aeration, and request verified water exchange."

    if risk_level == "warning":
        return "Reduce feed and increase aeration before chemistry crosses critical limits."

    return "Continue routine monitoring."
