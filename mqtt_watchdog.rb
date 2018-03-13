#!/usr/bin/ruby
#
# mqtt_watchdog.rb
#
# Usage:
#   $ sudo gem install mqtt
#   $ git clone https://github.com/yoggy/mqtt_watchdog.git
#   $ cd mqtt_watchdog
#   $ cp config.yaml.sample config.yaml
#   $ vi config.yaml
#
#       mqtt_host:     mqtt.example.com
#       mqtt_port:     1883
#       mqtt_use_auth: false
#       mqtt_username: username
#       mqtt_password: password
#       mqtt_subscribe_topic: subscribe_topic
#       mqtt_subscribe_timeout: 180,
#       mqtt_publish_topic: publish_topic
#       mqtt_publish_message_down: down message
#       mqtt_publish_message_reset: reset message
#
#   $ ./mqtt_watchdog.rb config.yaml
#
# License:
#   Copyright (c) 2018 yoggy <yoggy0@gmail.com>
#   Released under the MIT license
#   http://opensource.org/licenses/mit-license.php;
#
require 'mqtt'
require 'json'
require 'yaml'
require 'ostruct'
require 'pp'

$stdout.sync = true
Dir.chdir(File.dirname($0))
$current_dir = Dir.pwd

$log = Logger.new(STDOUT)
$log.level = Logger::DEBUG

def usage
  puts <<-EOS
usage : #{$0} [configuration yaml file]

example :

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

   $ #{$0} config.yaml

EOS
  exit(0)
end
usage if ARGV.size != 1

$conf = OpenStruct.new(YAML.load_file(ARGV[0]))

$down_flag = false
$last_update_t = Time.now

def update_t
  $down_flag = false
  $last_update_t = Time.now
end

def diff_t
  Time.now.to_i - $last_update_t.to_i
end

# watch dog thread
Thread.start do
  sleep 1
  loop do
    begin

      if diff_t > $conf.mqtt_subscribe_timeout && $down_flag == false
        $log.warn "publish message : topic=#{$conf.mqtt_publish_topic}, message=#{$conf.mqtt_publish_message_down}"
        $c.publish($conf.mqtt_publish_topic, $conf.mqtt_publish_message_down)
        $down_flag = true
      end
    rescue Exception => e
      $log.error(e)
      $log.error(e.backtrace)
    end
    sleep 1
  end
end

def main
  conn_opts = {
    remote_host: $conf.mqtt_host
  }

  if $conf.mqtt_port > 0
    conn_opts["remote_port"] = $conf.mqtt_port
  end

  if $conf.mqtt_use_auth == true
    conn_opts["username"] = $conf.mqtt_username
    conn_opts["password"] = $conf.mqtt_password
  end

  $log.info "connecting..."
  MQTT::Client.connect(conn_opts) do |c|
    $log.info "connected"

    # for watchdog thread
    $c = c

    $log.info "subscribe topic=" + $conf.mqtt_subscribe_topic
    c.get($conf.mqtt_subscribe_topic) do |t, msg|
      $log.info "received message : msg.size=#{msg.size}"

      if $down_flag == true && $conf.to_h.key?(:mqtt_publish_message_reset)
        $log.warn "publish message : topic=#{$conf.mqtt_publish_topic}, message=#{$conf.mqtt_publish_message_reset}"
        c.publish($conf.mqtt_publish_topic, $conf.mqtt_publish_message_reset)
      end

      update_t
    end
  end
end

if __FILE__ == $0
  loop do
    begin
      main
    rescue Exception => e
      exit(0) if e.class.to_s == "Interrupt"
      $log.error e
      $log.info "reconnect after 5 second..."
      sleep 5
    end
  end
end
