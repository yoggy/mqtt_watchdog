mqtt_watchdog.rb
====

Usage
----

    $ sudo gem install mqtt
    $ git clone https://github.com/yoggy/mqtt_watchdog.git
    $ cd mqtt_watchdog
    $ cp config.yaml.sample config.yaml
    $ vi config.yaml
 
        mqtt_host:     mqtt.example.com
        mqtt_port:     1883
        mqtt_use_auth: false
        mqtt_username: username
        mqtt_password: password
        mqtt_subscribe_topic: subscribe_topic
        mqtt_subscribe_timeout: 180,
        mqtt_publish_topic: publish_topic
        mqtt_publish_message_down: down message
        mqtt_publish_message_reset: reset message
 
    $ ./mqtt_watchdog.rb config.yaml
 
Copyright and license
----
Copyright (c) 2018 yoggy

Released under the [MIT license](LICENSE.txt)
