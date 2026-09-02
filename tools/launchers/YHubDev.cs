using System;
using System.Diagnostics;
using System.IO;
using System.Net.Sockets;

internal static class YHubDev
{
	private static int Main(string[] args)
	{
		Console.Title = "Y Hub Dev";

		try
		{
			string toolsDirectory = AppDomain.CurrentDomain.BaseDirectory;
			string projectRoot = Path.GetFullPath(Path.Combine(toolsDirectory, ".."));
			string scriptPath = Path.Combine(toolsDirectory, "dev", "dev-listener.js");
			int port = ReadPort(args, 8124);

			if (IsPortOpen(port))
			{
				WriteReadyStatus(port, "already running");
				WaitForExit();
				return 0;
			}

			if (!File.Exists(scriptPath))
			{
				Console.Error.WriteLine("[Y Hub Dev] Missing dev-listener.js next to this executable.");
				Console.Error.WriteLine("[Y Hub Dev] Expected: " + scriptPath);
				return 1;
			}

			string nodePath = FindNode();

			if (nodePath == null)
			{
				Console.Error.WriteLine("[Y Hub Dev] Node.js was not found in PATH or Program Files.");
				Console.Error.WriteLine("[Y Hub Dev] Install Node.js, then run this launcher again.");
				return 1;
			}

			string argumentText = Quote(scriptPath) + " --root " + Quote(projectRoot);

			foreach (string argument in args)
			{
				argumentText += " " + Quote(argument);
			}

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
					Console.Error.WriteLine("[Y Hub Dev] Could not start Node.js.");
					return 1;
				}

				process.WaitForExit();

				if (process.ExitCode != 0)
				{
					Console.ForegroundColor = ConsoleColor.Red;
					Console.Error.WriteLine("[Y Hub Dev] Listener closed with exit code " + process.ExitCode + ".");
					Console.ResetColor();
					WaitForExit();
				}

				return process.ExitCode;
			}
		}
		catch (Exception exception)
		{
			Console.Error.WriteLine("[Y Hub Dev] Launcher failed: " + exception);
			WaitForExit();
			return 1;
		}
	}

	private static int ReadPort(string[] args, int fallback)
	{
		for (int index = 0; index < args.Length - 1; index++)
		{
			if (string.Equals(args[index], "--port", StringComparison.OrdinalIgnoreCase))
			{
				int parsedPort;
				if (int.TryParse(args[index + 1], out parsedPort) && parsedPort > 0)
				{
					return parsedPort;
				}
			}
		}

		return fallback;
	}

	private static bool IsPortOpen(int port)
	{
		try
		{
			using (TcpClient client = new TcpClient())
			{
				IAsyncResult connection = client.BeginConnect("127.0.0.1", port, null, null);
				if (!connection.AsyncWaitHandle.WaitOne(250))
				{
					return false;
				}

				client.EndConnect(connection);
				return true;
			}
		}
		catch
		{
			return false;
		}
	}

	private static void WriteReadyStatus(int port, string state)
	{
		Console.ForegroundColor = ConsoleColor.Magenta;
		Console.WriteLine("Y Hub Dev");
		Console.ResetColor();
		Console.WriteLine();
		Console.WriteLine("Listener [" + port + "]: " + state);
		Console.WriteLine("Loader: http://127.0.0.1:" + port + "/loader.lua");
		Console.WriteLine("Agent:  http://127.0.0.1:" + port + "/agent.lua");
	}

	private static void WaitForExit()
	{
		Console.WriteLine();
		Console.WriteLine("Press Enter to close this window. The active listener will keep running.");
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
