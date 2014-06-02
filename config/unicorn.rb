if ENV['RACK_ENV'] == "production"
  # set path to app that will be used to configure unicorn,
  # note the trailing slash in this example
  @dir = "/var/lib/webapp/apps/gcal2dailyplanner/"

  # Specify path to socket unicorn listens to,
  # we will use this in our nginx.conf later
  listen "/tmp/unicorn.sock", :backlog => 64

  # store the pid file under /var/run directory
  pid "/tmp/unicorn.pid"
else
  # set path to app that will be used to configure unicorn,
  # note the trailing slash in this example
  @dir = "/Users/kazu634/works/sinatra_test/"

  # Specify the port number.
  listen 3000

  # store the pid file under /var/run directory
  pid "#{@dir}unicorn.pid"
end

# number of worker processes:
worker_processes 2

# working directory:
working_directory @dir

# timeout:
timeout 30

# log files:
if ENV['RACK_ENV'] == "production"
  # Set log file paths
  stderr_path "/var/log/gcalendar/unicorn.stderr.log"
  stdout_path "/var/log/gcalendar/unicorn.stdout.log"
end

# preload_app:
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
    GC.copy_on_write_friendly = true

# workerをforkする前の処理
before_fork do |server, worker|
  # http://techracho.bpsinc.jp/baba/2012_08_29/6001
  defined?(ActiveRecord::Base) && ActiveRecord::Base.connection.disconnect!

  # 古いPIDファイル取得
  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    # 古いPIDがある場合
    begin
      # 古いmasterプロセスを終了させる
      Process.kill('QUIT', File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end
