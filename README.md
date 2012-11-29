logstash-puppetized
===================

otherapp represents a log-producing app running on the same host as the logstash shipper (aka "producer")
otherapp could be apache, or tomcat, or whatever

so, all your other modules could have a logstash.input & logstash.filter template (and the logstash::producer::logs declaration in their manifest.)

also include logstash::producer in your host manifests, then whatever modules also happen to be on that node, logstash::producer will pull in their config fragments.
and because the whole filter chain for a given app is in one file, order is taken care of

a note about architecture...

this module puts a rabbitmq on every producer host, and logstash::producer has an output to send to the localhost rabbitmq over amqp.
the producer hosts export resources which are collected by logstash::consumer.  these exported resources are amqp input fragments, which the consumer uses to connects to all those rabbitmqs on the producer hosts.

this architecture is not for everyone, so you should consider reworking that part (or leaving it behind entirely) if you decide to use this module for anything.
