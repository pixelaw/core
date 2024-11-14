module.exports = {
  apps : [{
    name: 'katana',
    script: '/pixelaw/scripts/katana_start.sh',
    out_file: '/pixelaw/log/katana.log',
    error_file: '/pixelaw/log/katana.log',
    merge_logs: true,
    time: true
  },{
    name: 'torii',
    script: '/pixelaw/scripts/torii_start.sh',
    out_file: '/pixelaw/log/torii.log',
    error_file: '/pixelaw/log/torii.log',
    merge_logs: true,
    time: true
  },{
    name: 'server',
    script: '/pixelaw/scripts/server_start.sh',
    out_file: '/pixelaw/log/server.log',
    error_file: '/pixelaw/log/server.log',
    merge_logs: true,
    time: true
  }]
};
