# Class is a marker class to ensure that the Kafka libraries are installed on the machine.
#
#
class confluent::kafka::connect {
  include ::confluent
  include ::confluent::kafka
}