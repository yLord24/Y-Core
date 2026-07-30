using System;
using System.Diagnostics;
using System.IO;

internal static class YCoreDevServer
{
	private static int Main(string[] args)
	{
		try
		{
			string toolDirectory = AppDomain.CurrentDomain.BaseDirectory;
			string scriptPath = Path.Combine(toolDirectory, "dev-listener.js");

			if (!File.Exists(scriptPath))
			{
				Console.Error.WriteLine("[YCore Dev] Missing dev-listener.js next to this executable.");
				Console.Error.WriteLine("[YCore Dev] Expected: " + scriptPath);
				return 1;
			}

			string nodePath = FindNode();

			if (nodePath == null)
			{
				Console.Error.WriteLine("[YCore Dev] Node.js was not found in PATH or Program Files.");
				Console.Error.WriteLine("[YCore Dev] Install Node.js or run tools/start-dev-listener.ps1.");
				return 1;
			}

			string argumentText = Quote(scriptPath);

			foreach (string argument in args)
			{
				argumentText += " " + Quote(argument);
			}

			ProcessStartInfo startInfo = new ProcessStartInfo
			{
				FileName = nodePath,
				Arguments = argumentText,
				WorkingDirectory = Path.GetFullPath(Path.Combine(toolDirectory, "..")),
				UseShellExecute = false,
				CreateNoWindow = false,
			};

			using (Process process = Process.Start(startInfo))
			{
				if (process == null)
				{
					Console.Error.WriteLine("[YCore Dev] Could not start Node.js.");
					return 1;
				}

				process.WaitForExit();
				return process.ExitCode;
			}
		}
		catch (Exception exception)
		{
			Console.Error.WriteLine("[YCore Dev] Launcher failed: " + exception);
			return 1;
		}
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
