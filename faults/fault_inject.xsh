#!/usr/bin/env xonsh


def cpu_slow(slow_server_config, slow_ip, slow_pids):
    quota=50000
    period=1000000
    ssh -i ~/.ssh/id_rsa @(slow_ip) "sudo sh -c 'sudo mkdir /sys/fs/cgroup/cpu/db'"
    ssh -i ~/.ssh/id_rsa @(slow_ip) @("sudo sh -c 'sudo echo {} > /sys/fs/cgroup/cpu/db/cpu.cfs_quota_us'".format(quota))
    ssh -i ~/.ssh/id_rsa @(slow_ip) @("sudo sh -c 'sudo echo {} > /sys/fs/cgroup/cpu/db/cpu.cfs_period_us'".format(period))
    
    for slow_pid in slow_pids.split():
        ssh -i ~/.ssh/id_rsa @(slow_ip) @("sudo sh -c 'sudo echo {} > /sys/fs/cgroup/cpu/db/cgroup.procs'".format(slow_pid))

def cpu_slow_docker(slow_server_config, slow_cid, slow_pids):
    quota=10000
    period=1000000
    sudo docker exec -it @(slow_cid) sudo sh -c "sudo mkdir /sys/fs/cgroup/cpu/db"
    sudo docker exec -it @(slow_cid) sudo sh -c @("sudo echo {} > /sys/fs/cgroup/cpu/db/cpu.cfs_quota_us".format(quota))
    sudo docker exec -it @(slow_cid) sudo sh -c @("sudo echo {} > /sys/fs/cgroup/cpu/db/cpu.cfs_period_us".format(period))
    sudo docker exec -it @(slow_cid) sudo sh -c @("sudo echo {} > /sys/fs/cgroup/cpu/db/cgroup.procs".format(1))

def cpu_contention(slow_server_config, slow_ip, slow_pids):
    cpu = slow_server_config['cpu']
    scp resources/slowness/deadloop @(slow_ip):~/
    ssh -i ~/.ssh/id_rsa @(slow_ip) f"sh -c 'nohup taskset -ac {cpu} ./deadloop > /dev/null 2>&1 &'"
    deadlooppid=$(ssh -i ~/.ssh/id_rsa @(slow_ip) "sh -c 'pgrep deadloop'")
    ssh -i ~/.ssh/id_rsa @(slow_ip) "sudo sh -c 'sudo mkdir /sys/fs/cgroup/cpu/cpulow /sys/fs/cgroup/cpu/cpuhigh'"
    ssh -i ~/.ssh/id_rsa @(slow_ip) "sudo sh -c 'sudo echo 64 > /sys/fs/cgroup/cpu/cpulow/cpu.shares'"
    ssh -i ~/.ssh/id_rsa @(slow_ip) @("sudo sh -c 'sudo echo {} > /sys/fs/cgroup/cpu/cpuhigh/cgroup.procs'".format(deadlooppid))

    for slow_pid in slow_pids.split():
        ssh -i ~/.ssh/id_rsa @(slow_ip) @("sudo sh -c 'sudo echo {} > /sys/fs/cgroup/cpu/cpulow/cgroup.procs'".format(slow_pid))

def cpu_contention_docker(slow_server_config, slow_cid, slow_pids):
    sudo docker exec -t @(slow_cid) sudo sh -c "tc qdisc add dev eth0 root netem loss 3%"
    #we use this for lossy network :P
    
def disk_slow(slow_server_config, slow_ip, slow_pids):
    ssh -i ~/.ssh/id_rsa @(slow_ip) "sudo sh -c 'sudo mkdir /sys/fs/cgroup/blkio/db'"
    ssh -i ~/.ssh/id_rsa @(slow_ip) "sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'"
    lsblkcmd="8:32 524288"
    ssh -i ~/.ssh/id_rsa @(slow_ip) f"sudo sh -c 'sudo echo {lsblkcmd} > /sys/fs/cgroup/blkio/db/blkio.throttle.read_bps_device'"
    ssh -i ~/.ssh/id_rsa @(slow_ip) f"sudo sh -c 'sudo echo {lsblkcmd} > /sys/fs/cgroup/blkio/db/blkio.throttle.write_bps_device'"
    for slow_pid in slow_pids.split():
        ssh -i ~/.ssh/id_rsa @(slow_ip) @("sudo sh -c 'sudo echo {} > /sys/fs/cgroup/blkio/db/cgroup.procs'".format(slow_pid))

def disk_slow_docker(slow_server_config, slow_cid, slow_pids):
    sudo docker exec -it @(slow_cid) sudo sh -c  "mkdir /sys/fs/cgroup/blkio/db"
    sudo docker exec -it @(slow_cid) sudo sh -c  "sync; echo 3 > /proc/sys/vm/drop_caches"
    lsblkcmd="8:32 524288"
    sudo docker exec -it @(slow_cid) sudo sh -c f"echo {lsblkcmd} > /sys/fs/cgroup/blkio/db/blkio.throttle.read_bps_device"
    sudo docker exec -it @(slow_cid) sudo sh -c f"echo {lsblkcmd} > /sys/fs/cgroup/blkio/db/blkio.throttle.write_bps_device"
    sudo docker exec -it @(slow_cid) sudo sh -c  @("echo {} > /sys/fs/cgroup/blkio/db/cgroup.procs".format(1))

def disk_contention(slow_server_config, slow_ip, slow_pids):
    ssh -i ~/.ssh/id_rsa @(slow_ip) "sh -c 'nohup taskset -ac 2 ./clear_dd_file.sh > /dev/null 2>&1 &'"

def disk_contention_docker(slow_server_config, slow_cid, slow_pids):
    sudo docker exec -it @(slow_cid) sudo sh -c "nohup taskset -ac 2 slooo/faults/./clear_dd_file.sh > /dev/null 2>&1 &"

def network_slow(slow_server_config, slow_ip, slow_pids):
    ssh -i ~/.ssh/id_rsa @(slow_ip) "sudo sh -c 'sudo /sbin/tc qdisc add dev eth0 root netem delay 400ms'"

def network_slow_docker(slow_server_config, slow_cid, slow_pids):
    sudo docker exec -it @(slow_cid) sudo sh -c "tc qdisc add dev eth0 root netem delay 500ms"

def memory_contention(slow_server_config, slow_ip, slow_pids):
    ssh -i ~/.ssh/id_rsa @(slow_ip) "sudo sh -c 'sudo mkdir /sys/fs/cgroup/memory/db'"
    #ssh -i ~/.ssh/id_rsa "$host_id"@"$slow_ip" "sudo sh -c 'sudo echo 1 > /sys/fs/cgroup/memory/db/memory.memsw.oom_control'"  # disable OOM killer
    #ssh -i ~/.ssh/id_rsa "$host_id"@"$slow_ip" "sudo sh -c 'sudo echo 10485760 > /sys/fs/cgroup/memory/db/memory.memsw.limit_in_bytes'"   # 10MB
    # ssh -i ~/.ssh/id_rsa "$host_id"@"$slow_ip" "sudo sh -c 'sudo echo 1 > /sys/fs/cgroup/memory/db/memory.oom_control'"  # disable OOM killer
    ssh -i ~/.ssh/id_rsa @(slow_ip) "sudo sh -c 'sudo echo @(5 * 1024 * 1024) > /sys/fs/cgroup/memory/db/memory.limit_in_bytes'"   # 5MB
    
    for slow_pid in slow_pids.split():
        ssh -i ~/.ssh/id_rsa @(slow_ip) @("sudo sh -c 'sudo echo {} > /sys/fs/cgroup/memory/db/cgroup.procs'".format(slow_pid))

def memory_contention_docker(slow_server_config, slow_cid, slow_pids):
    sudo docker exec -it @(slow_cid) sudo sh -c "sudo mkdir /sys/fs/cgroup/memory/db"
    sudo docker exec -it @(slow_cid) sudo sh -c "sudo echo @(5 * 1024 * 1024) > /sys/fs/cgroup/memory/db/memory.limit_in_bytes"   # 5MB
    sudo docker exec -it @(slow_cid) sudo sh -c f"sudo echo {1} > /sys/fs/cgroup/memory/db/cgroup.procs"


def kill_process(ip, pids):
    for pid in pids.split():
        ssh -i ~/.ssh/id_rsa @(ip) f"sudo sh -c 'kill -9 {pid}'"

def kill_process_docker(cid, pids):
    for pid in pids.split():
        sudo docker exec -it @(cid) f"sudo sh -c 'kill -9 {pid}'"

slow_vs_num = {1: cpu_slow,
               2: cpu_contention,
               3: disk_slow,
               4: disk_contention,
               5: memory_contention,
               6: network_slow}

slow_vs_num_docker = {1: cpu_slow_docker,
               2: cpu_contention_docker,
               3: disk_slow_docker,
               4: disk_contention_docker,
               5: memory_contention_docker,
               6: network_slow_docker}

def fault_inject(exp, server_config, pids, snooze):
    sleep @(snooze)
    ip = server_config["ip"]
    if exp == "kill":
        kill_process(ip, pids)
    elif exp == "noslow":
        pass
    else:
        slow_vs_num[int(exp)](server_config, ip, pids)

def fault_inject_docker(exp, server_config, pids, snooze):
    sleep @(snooze)
    cid = server_config["cid"]
    if exp == "kill":
        kill_process(cid, pids)
    elif exp == "noslow":
        pass
    else:
        slow_vs_num_docker[int(exp)](server_config, cid, pids)
