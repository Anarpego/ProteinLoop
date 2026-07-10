alias ProteinLoop.Agent.SagentsEvidence

root = Path.expand("../..", __DIR__)
submission = Path.join(root, "submission")
File.mkdir_p!(submission)

case SagentsEvidence.build() do
  {:ok, evidence} ->
    json_path = Path.join(submission, "sagents-evidence.json")
    md_path = Path.join(submission, "sagents-evidence.md")

    File.write!(json_path, Jason.encode!(evidence, pretty: true) <> "\n")
    File.write!(md_path, SagentsEvidence.render_markdown(evidence))

    IO.puts("wrote #{Path.relative_to_cwd(json_path)}")
    IO.puts("wrote #{Path.relative_to_cwd(md_path)}")

  {:error, reason} ->
    IO.puts(:stderr, "Sagents evidence failed: #{inspect(reason, pretty: true)}")
    System.halt(1)
end
