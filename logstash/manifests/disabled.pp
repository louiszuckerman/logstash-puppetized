class logstash::disabled($logstash_syslog_host, $logstash_syslog_port, $logstash_syslog_proto = "tcp") inherits logstash::producer {
  Service["logstash-producer"] {
    ensure => "stopped",
    enable => false
  }
  Service["rabbitmq-server"] {
    ensure => "stopped",
    enable => false
  }
  $syslog_prefix = $logstash_syslog_proto ? {
      'udp' => '@',
      default => '@@'
  }
  File["/etc/rsyslog.d/logstash.conf"] {
  	content => "*.* ${syslog_prefix}${logstash_syslog_host}:${logstash_syslog_port}"
  }
  Nagios::Target::Nrpeservicecheck["logstash-producer-process"] {
  	enable => false
  }
  Nagios::Target::Nrpeservicecheck["rabbitmq-server-process"] {
    enable => false
  }
  Nagios::Target::Nrpeservicecheck["logstash-syslog-tcp"] {
    enable => false
  }
  
}