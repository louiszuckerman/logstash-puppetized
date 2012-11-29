class logstash::producer($amqp_enabled = true) inherits logstash {
  include logstash
  
  $logstash_producer_config = "/opt/logstash/producer.conf"
  
#  nagios::target::nrpeservicecheck {
#    "logstash-producer-process":
#      description => "LogstashProducer",
#      command => "check_procs -c 1:1 -C java -a producer.conf";
#    "rabbitmq-server-process":
#      description => "RabbitMQ Service",
#      command => "check_tcp -H localhost -p 5672";
#    "logstash-syslog-tcp":
#      description => "Logstash SyslogTCP",
#      command => "check_tcp -H localhost -p 5514";
#  }
  
  if defined(Class["logstash::consumer"]) {
    concat::fragment {
      "logstash-producer-host-${::clientcert}":
        tag => "logstash-producer-host",
        content => template("logstash/producer-host.conf");
    }
  } elsif ( ! defined(Class["logstash::disabled"]) ) {
    @@concat::fragment {
      "logstash-producer-host-${::clientcert}":
        tag => "logstash-producer-host",
        content => template("logstash/producer-host.conf");
    }
  }  
  
  define logs($has_grok = false) {
    @concat::fragment {
      "logstash-producer-input-${name}":
        content => template("${name}/logstash.input"),
        tag => "logstash-producer-input";
    }
    @concat::fragment {
      "logstash-producer-filter-${name}":
        content => template("${name}/logstash.filter"),
        tag => "logstash-producer-filter";
    }
    if $has_grok {
      file {
        "/opt/logstash/patterns/${name}":
          content => template("${name}/logstash.grok"),
          replace => true,
          ensure => present,
          require => File["/opt/logstash/patterns"],
          notify => Service["logstash-producer"];
      }
    }
  }
  
  service {
    "logstash-producer":
      ensure => running,
      hasstatus => true,
      hasrestart => true,
      require => [ File["/etc/init.d/logstash-producer"], Concat["${logstash_producer_config}"] ],
      subscribe => File["/opt/logstash/logstash.jar"];
  }
  
  if ! defined(Service["rsyslog"]) {
    service {
      "rsyslog":
        ensure => running,
        hasrestart => true;
    }
  }
  
  file {
    "/etc/init.d/logstash-producer":
      ensure => "/lib/init/upstart-job",
      require => File["/etc/init/logstash-producer.conf"];
    "/etc/init/logstash-producer.conf":
      ensure => present,
      replace => true,
      content => template("logstash/producer.upstart"),
      notify => Service["logstash-producer"],
      require => Service["rabbitmq-server"];
    "/etc/rsyslog.d/logstash.conf":
      ensure => present,
      replace => true,
      content => '*.* @@127.0.0.1:5514',
      notify => Service["rsyslog"];
  }
  
  concat {
    "$logstash_producer_config":
      notify => Service["logstash-producer"];
  }

  concat::fragment {
    "logstash-producer-pre-input":
      content => template("logstash/pre-input.conf"),
      order => 10,
      target => "$logstash_producer_config";

    "logstash-producer-common-input":
      content => template("logstash/producer-common-input.conf"),
      order => 11,
      target => "$logstash_producer_config";
  }
  
  Concat::Fragment<| tag == "logstash-producer-input" |> {
    target => "$logstash_producer_config",
    order => 15
  }
  
  concat::fragment {
    "logstash-producer-pre-filter":
      content => template("logstash/pre-filter.conf"),
      order => 20,
      target => "$logstash_producer_config";

    "logstash-producer-common-filter":
      content => template("logstash/producer-common-filter.conf"),
      order => 21,
      target => "$logstash_producer_config";
  }

  Concat::Fragment<| tag == "logstash-producer-filter" |> {
    target => "$logstash_producer_config",
    order => 25
  }
  
  concat::fragment {
    "logstash-producer-output":
      content => template("logstash/producer-output.conf"),
      order => 30,
      target => "$logstash_producer_config";
  }
  
  service {
    "rabbitmq-server":
      ensure => running,
      enable => true,
      hasstatus => true,
      hasrestart => true,
      require => Package["rabbitmq-server"];
  }
  
  package {
    "rabbitmq-server":
      ensure => present;
  }
}
