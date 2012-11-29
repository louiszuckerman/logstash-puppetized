class logstash::consumer($logstash_device) {
  $logstash_mount = "/logstash"
  $logstash_consumer_config = "/opt/logstash/consumer.conf"
  
#  nagios::target::nrpeservicecheck {
#    "logstash-consumer-process":
#      description => "LogstashConsumer PROCESS",
#      command => "check_procs -c 1:1 -C java -a consumer.conf";
#  }
  
  service {
    "logstash-consumer":
      ensure => running,
      hasstatus => true,
      hasrestart => true,
      require => [ File["/opt/logstash/data"], Concat["${logstash_consumer_config}"] ],
      subscribe => File["/opt/logstash/logstash.jar"];
  }
  
  file {
    "/opt/logstash/data":
      ensure => "${logstash_mount}/data",
      require => File["${logstash_mount}/data"];
    "${logstash_mount}/data":
      ensure => directory,
      owner => 'nobody', group => 'nogroup',
      require => Mount["${logstash_mount}"];
    "/etc/init.d/logstash-consumer":
      ensure => "/lib/init/upstart-job",
      require => File["/etc/init/logstash-consumer.conf"];
    "/etc/init/logstash-consumer.conf":
      ensure => present,
      replace => true,
      content => template("logstash/consumer.upstart"),
      notify => Service["logstash-consumer"],
      require => File["/etc/security/limits.d/logstash-consumer.conf"];
    "/etc/security/limits.d/logstash-consumer.conf":
      content => template("logstash/consumer.limit"),
      replace => true,
      ensure => present;
  }
  
  mount {
    "${logstash_mount}":
      ensure => mounted,
      device => "${logstash_device}",
      options => "noatime,nodiratime",
      fstype => "auto",
      dump => 0,
      pass => 0,
      remounts => true,
      require => File["${logstash_mount}"];
  }
  
  file {
    "${logstash_mount}":
      ensure => directory,
      require => File["/opt/logstash"];
  }
  
  concat {
    "${logstash_consumer_config}":
      notify => Service["logstash-consumer"],
      require => Class["logstash"];
  }

  concat::fragment {
    "logstash-consumer-pre-input":
      content => template("logstash/pre-input.conf"),
      order => 10,
      target => "${logstash_consumer_config}";
  }
  
  Concat::Fragment<<| tag == "logstash-producer-host" |>> {
    target => "${logstash_consumer_config}",
    order => 15
  }
  
  concat::fragment {
    "logstash-consumer-output":
      content => template("logstash/consumer-output.conf"),
      order => 30,
      target => "${logstash_consumer_config}";
  }

}
