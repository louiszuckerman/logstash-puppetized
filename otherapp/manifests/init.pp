class otherapp {
    
    # ...
    
    logstash::producer::logs{
        "otherapp": has_grok => true;
    }
    
    # ...
}