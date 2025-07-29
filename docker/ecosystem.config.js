module.exports = {
  apps : [{
    name: 'katana',
    script: '/pixelaw/scripts/katana_start.sh',
    out_file: '/proc/1/fd/1',
    error_file: '/proc/1/fd/2',
    merge_logs: true,
    time: true
  },{
    name: 'torii',
    script: '/pixelaw/scripts/torii_start.sh',
    out_file: '/proc/1/fd/1',
    error_file: '/proc/1/fd/2',
    merge_logs: true,
    time: true
  },{
    name: 'server',
    script: '/pixelaw/scripts/server_start.sh',
    out_file: '/proc/1/fd/1',
    error_file: '/proc/1/fd/2',
    merge_logs: true,
    time: true
  }]
};
