# set path to app that will be used to configure unicorn,
# note the trailing slash in this example
@dir = "/Users/kazu634/works/sinatra_test/"

worker_processes 2
working_directory @dir

timeout 30

# Specify path to socket unicorn listens to,
# we will use this in our nginx.conf later
#listen "#{@dir}tmp/sockets/unicorn.sock", :backlog => 64
listen 3000

# Set process id path
pid "#{@dir}tmp/pids/unicorn.pid"

# Set log file paths
#stderr_path "#{@dir}log/unicorn.stderr.log"
#stdout_path "#{@dir}log/unicorn.stdout.log"

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
