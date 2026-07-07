alias ProteinLoop.Agent.MeshEvidence

root = Path.expand("../..", __DIR__)
submission = Path.join(root, "submission")
File.mkdir_p!(submission)

packet = MeshEvidence.build()
json_path = Path.join(submission, "mesh-evidence.json")
md_path = Path.join(submission, "mesh-evidence.md")

File.write!(json_path, Jason.encode!(MeshEvidence.to_jsonable(packet), pretty: true) <> "\n")
File.write!(md_path, MeshEvidence.render_markdown(packet))

IO.puts("wrote #{Path.relative_to_cwd(json_path)}")
IO.puts("wrote #{Path.relative_to_cwd(md_path)}")
