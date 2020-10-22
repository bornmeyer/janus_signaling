defmodule Mix.Tasks.CallService.Start do
    use Mix.Task
    require Logger

    @shortdoc "runs the call service"
    def run(opts) do
        opts
        |> parse_args
        |> process
    
        Mix.Tasks.Run.run run_args() #++ opts
    end
  
    defp run_args do
      if iex_running?(), do: [], else: ["--no-halt"]
    end
  
    defp iex_running? do
      Code.ensure_loaded?(IEx) and IEx.started?
    end
  
    defp process(opts) do
      ip = opts[:ip] || "127.0.0.1"
      port = opts[:port] || 8765          
      Application.put_env(:general, :ip, ip, persistent: true)
      Application.put_env(:general, :port, port, persistent: true)
    end
  
    defp parse_args(argv) do
      parse = OptionParser.parse(argv, switches: [ ip: :string,
                                                    port:   :integer ])
      case parse do
        { options       , _, _ } -> options
      end
    end
end