using System;
using System.Diagnostics;
using System.IO;

internal static class YHubBuild
{
	private static int Main(string[] args)
	{
		try
		{
			string toolsDirectory = AppDomain.CurrentDomain.BaseDirectory;
			string projectRoot = Path.GetFullPath(Path.Combine(toolsDirectory, ".."));
			string scriptPath = Path.Combine(toolsDirectory, "build", "build-game.js");

			if (!File.Exists(scriptPath))
			{
				Console.Error.WriteLine("[Y Hub Build] Missing build-game.js.");
				Console.Error.WriteLine("[Y Hub Build] Expected: " + scriptPath);
				Pause();
				return 1;
			}

			string nodePath = FindNode();

			if (nodePath == null)
			{
				Console.Error.WriteLine("[Y Hub Build] Node.js was not found in PATH or Program Files.");
				Pause();
				return 1;
			}

			string gameId = args.Length > 0 ? args[0] : AskGameId();

			if (string.IsNullOrWhiteSpace(gameId))
			{
				Console.Error.WriteLine("[Y Hub Build] No game selected.");
				Pause();
				return 1;
			}

			string argumentText = Quote(scriptPath)
				+ " --root " + Quote(projectRoot)
				+ " --game " + Quote(gameId.Trim())
				+ " --release";

			for (int argumentIndex = 1; argumentIndex < args.Length; argumentIndex += 1)
			{
				argumentText += " " + Quote(args[argumentIndex]);
			}

			Console.WriteLine("[Y Hub Build] Building " + gameId.Trim() + "...");
			Console.WriteLine("");

			ProcessStartInfo startInfo = new ProcessStartInfo
			{
				FileName = nodePath,
				Arguments = argumentText,
				WorkingDirectory = projectRoot,
				UseShellExecute = false,
				CreateNoWindow = false,
			};

			using (Process process = Process.Start(startInfo))
			{
				if (process == null)
				{
					Console.Error.WriteLine("[Y Hub Build] Could not start Node.js.");
					Pause();
					return 1;
				}

				process.WaitForExit();
				Console.WriteLine("");
				Console.WriteLine(process.ExitCode == 0 ? "[Y Hub Build] Done." : "[Y Hub Build] Failed.");
				Pause();
				return process.ExitCode;
			}
		}
		catch (Exception exception)
		{
			Console.Error.WriteLine("[Y Hub Build] Launcher failed: " + exception);
			Pause();
			return 1;
		}
	}

	private static string AskGameId()
	{
		Console.WriteLine("Y Hub Build");
		Console.Write("Game id: ");
		return Console.ReadLine() ?? "";
	}

	private static void Pause()
	{
		Console.WriteLine("");
		Console.Write("Press Enter to close...");
		Console.ReadLine();
	}

	private static string FindNode()
	{
		string pathValue = Environment.GetEnvironmentVariable("PATH") ?? "";

		foreach (string folder in pathValue.Split(Path.PathSeparator))
		{
			if (string.IsNullOrWhiteSpace(folder))
			{
				continue;
			}

			string candidate = Path.Combine(folder.Trim(), "node.exe");

			if (File.Exists(candidate))
			{
				return candidate;
			}
		}

		string programFiles = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
		string programFilesX86 = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86);
		string[] fallbackList =
		{
			Path.Combine(programFiles, "nodejs", "node.exe"),
			Path.Combine(programFilesX86, "nodejs", "node.exe"),
		};

		foreach (string fallback in fallbackList)
		{
			if (File.Exists(fallback))
			{
				return fallback;
			}
		}

		return null;
	}

	private static string Quote(string value)
	{
		if (value == null)
		{
			return "\"\"";
		}

		return "\"" + value.Replace("\"", "\\\"") + "\"";
	}
}
