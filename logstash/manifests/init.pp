class logstash {
  file {
    "/etc/logrotate.d/logstash":
      ensure => present,
      replace => true,
      content => template("logstash/logrotate");
    
    "/opt/logstash/logstash.jar":
      source => "puppet:///modules/logstash/logstash.jar",
      ensure => present,
#      links => follow,
      backup => false,
      replace => true,
      require => File["/opt/logstash"];
    
    "/opt/logstash/logs":
      ensure => directory,
      mode => 0777,
      require => File["/opt/logstash"];
    
    "/opt/logstash/patterns":
      ensure => directory,
      require => File["/opt/logstash"];
    
    "/opt/logstash":
      ensure => directory,
      require => Class["yourjavaclass"];
  }
}