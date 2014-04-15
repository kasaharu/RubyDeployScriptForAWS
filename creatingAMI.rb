require 'aws-sdk'
require 'dotenv'
require 'net/ssh'
Dotenv.load

ACCESS_KEY_ID        = ENV['ACCESS_KEY_ID']
SECRET_ACCESS_KEY    = ENV['SECRET_ACCESS_KEY']
REGION               = ENV['REGION']
BASE_AMI_NAME        = ENV['BASE_AMI_NAME']
INSTANCE_TYPE        = ENV['INSTANCE_TYPE']
KEY_PAIR             = ENV['KEY_PAIR']
ELB_NAME             = ENV['ELB_NAME']
SECURITY_GROUP       = ENV['SECURITY_GROUP']
AVAILABILITY_ZONE_A  = ENV['AVAILABILITY_ZONE_A']
AVAILABILITY_ZONE_C  = ENV['AVAILABILITY_ZONE_C']
EC2_ENDPOINT         = ENV['EC2_ENDPOINT']
ELB_ENDPOINT         = ENV['ELB_ENDPOINT']
REMOTE_USER          = ENV['REMOTE_USER']
SSH_KEY_FILE_PATH    = ENV['SSH_KEY_FILE_PATH']

AWS.config({
  region:            REGION,
  access_key_id:     ACCESS_KEY_ID,
  secret_access_key: SECRET_ACCESS_KEY,
  ec2_endpoint:      EC2_ENDPOINT,
  elb_endpoint:      ELB_ENDPOINT
})



INSTANCE_NAME        = "appServer_newInstnce_9"
NAME_TAG             = "Name"
GENERATION_TAG       = "Generation"
NEXT_GENERATION      = "next"
CURRENT_GENERATION   = "current"
PREVIOUS_GENERATION  = "previous"
DELETE_GENERATION    = "delete"




p "EC2 Task"
@ec2 = AWS::EC2.new(
  access_key_id: ACCESS_KEY_ID,
  secret_access_key: SECRET_ACCESS_KEY,
  region: REGION
)

############################## Create the EC2 Instance

@new_instance = @ec2.instances.create(
  image_id: BASE_AMI_NAME,
  instance_type: INSTANCE_TYPE,
  security_groups: SECURITY_GROUP,
  availability_zone: AVAILABILITY_ZONE_C,
  key_name: KEY_PAIR
)
@ec2.tags.create(@new_instance, NAME_TAG, value: INSTANCE_NAME)
@ec2.tags.create(@new_instance, GENERATION_TAG, value: NEXT_GENERATION)
p "New Instance is creating ..."

# Set IP Address
p "Status check."
loop do
  p "current status is #{@new_instance.status}."
  break if @new_instance.status.equal?(:running)
  sleep(20)
end
p "Status is #{@new_instance.status}!"

@all_instance_info = @ec2.client.describe_instances[:instance_index]
@all_instance_info.each_value do |instance_info|
  tag_set = instance_info[:tag_set]
  tag_set.each do |tag|
    if (tag[:key] == NAME_TAG && tag[:value] == INSTANCE_NAME)
      @instance_pub_ip_addr = @new_instance.public_ip_address
      @instance_id          = @new_instance.id
      @instance_dns_name    = @new_instance.public_dns_name
    end
  end
end









############################## Waiting status check

i = 210
while i > 0
  p "Please wait #{i} seconds."
  sleep(30)
  i -= 30
end
p "Finished status check."

############################## Running Chef

`knife solo prepare -i #{SSH_KEY_FILE_PATH} #{REMOTE_USER}@#{@instance_pub_ip_addr}`
p "solo prepare done."
`cat nodes/template.json > nodes/#{@instance_pub_ip_addr}.json`
p "copy template done."
##
##`scp -i #{SSH_KEY_FILE_PATH} #{APP_PATH}/#{APP_FILE_NAME} #{REMOTE_USER}@#{@instance_pub_ip_addr}:/home/#{REMOTE_USER}`
##`scp -i #{SSH_KEY_FILE_PATH} #{THIS_SCRIPT_PATH}/forRemoteServer/run_app.sh  #{REMOTE_USER}@#{@instance_pub_ip_addr}:/home/#{REMOTE_USER}`
##`scp -i #{SSH_KEY_FILE_PATH} #{THIS_SCRIPT_PATH}/forRemoteServer/.env.forApp  #{REMOTE_USER}@#{@instance_pub_ip_addr}:/home/#{REMOTE_USER}`
##
`knife solo cook -i #{SSH_KEY_FILE_PATH} #{REMOTE_USER}@#{@instance_pub_ip_addr}`
p "solo cook done."
p "installed ruby"

#Net::SSH.start(@instance_dns_name, REMOTE_USER, :keys => SSH_KEY_FILE_PATH) do |ssh|
#  print(ssh.exec!('tail ~/.bashrc > testtest.txt'))
#  print(ssh.exec!('source ~/.bashrc'))
#  print(ssh.exec!('exec $SHELL -l'))
#  print(ssh.exec!('mkdir /home/ubuntu/sample'))
#end

##`cat nodes/template_rails.json > nodes/#{@instance_pub_ip_addr}.json`
##`knife solo cook -i #{SSH_KEY_FILE_PATH} #{REMOTE_USER}@#{@instance_pub_ip_addr}`
##p "solo cook done."
##p "installed rails"

##p "@new_instance.exec_using_ssh!(cd /home/#{REMOTE_USER}/)"
##@new_instance.exec_using_ssh!("cd /home/#{REMOTE_USER}/")
##
##p "@new_instance.exec_using_ssh!(tar zxvf #{APP_FILE_NAME})"
##@new_instance.exec_using_ssh!("tar zxvf #{APP_FILE_NAME}")
##
##sleep(5)
##p "@new_instance.exec_using_ssh!(cd /home/#{REMOTE_USER}/nflc_key_server/; /home/#{REMOTE_USER}/.rbenv/shims/bundle install)"
##@new_instance.exec_using_ssh!("cd /home/#{REMOTE_USER}/nflc_key_server/; /home/#{REMOTE_USER}/.rbenv/shims/bundle install")
##
##sleep(5)
##p "@new_instance.exec_using_ssh!(bash /home/#{REMOTE_USER}/run_app.sh)"
##@new_instance.exec_using_ssh!("bash /home/#{REMOTE_USER}/run_app.sh")


p "Finished chef."


############################## Createing AMI

ami_name = "#{@new_instance.id}_#{DateTime.now.strftime("%Y%m%d%H%M%S")}"
ami_description = "Web Server Base AMI(#{@new_instance.tags['Name']}) at #{DateTime.now}"
new_created_ami = @new_instance.create_image(ami_name, {description: ami_description, no_reboot: true})
@ec2.tags.create(new_created_ami, NAME_TAG, value: "Base_AMI_#{DateTime.now.strftime("%Y%m%d")}")
p "AMI is Created!!!"





##
################################ Setting ELB
##
##p "ELB Task"
##elb_instance = AWS::ELB.new
##targeted_elb = elb_instance.load_balancers[ELB_NAME]
##
##@all_instance_id = []
##@ec2.instances.each do |instance|
##  @all_instance_id << instance.id
##end
##
##
################################ Change the Generation Tag to Lost Generation from Old Generation
##
##@all_instance_info.each_value do |value|
##  tag_set = value[:tag_set]
##  tag_set.each do |tag|
##    if (tag[:key] == GENERATION_TAG && tag[:value] == PREVIOUS_GENERATION)
##      old_to_lost_id = @all_instance_id.find{|elem| elem==value[:instance_id]}
##      old_instance = @ec2.instances[old_to_lost_id]
##      @ec2.tags.create(old_instance, GENERATION_TAG, value: DELETE_GENERATION)
##    end
##  end
##end
##
################################ Change the Generation Tag to Old Generation under Load Balancer
##
##@deregister_id = []
##instances_under_elb = targeted_elb.instances.select {|ins| ins.exists?}
##instances_under_elb.each do |instance_under_elb|
##  @ec2.tags.create(instance_under_elb, GENERATION_TAG, value: PREVIOUS_GENERATION)
##  p "instance_under_elb.id = #{instance_under_elb.id}"
##  @deregister_id << instance_under_elb.id
##end
##
################################ Attachment the new instance on ELB
##
##targeted_elb.instances.register(@new_instance)
##@ec2.tags.create(@new_instance, GENERATION_TAG, value: CURRENT_GENERATION)
##p "New EC2 instance is connected !!"
##
################################ Disconnect the Old Generation instance
##
##running_instances_under_elb = targeted_elb.instances.select {|ins| ins.exists? && ins.status == :running}
##running_instances_under_elb.each do |running_instance_under_elb|
##  stopped_id = @deregister_id.find{|elem| elem==running_instance_under_elb.id}
##  if !stopped_id.nil?
##    targeted_elb.instances.deregister(running_instance_under_elb)
##    @ec2.instances[running_instance_under_elb.id].stop
##  end
##end
##
##p "Old EC2 instances disconnect."
##
################################ Destroy the Lost Generation instance
##
##@all_instance_info.each_value do |value|
##  tag_set = value[:tag_set]
##  tag_set.each do |tag|
##    if (tag[:key] == GENERATION_TAG && tag[:value] == DELETE_GENERATION)
##      lost_id = value[:instance_id]
##      @ec2.instances[lost_id].terminate
##    end
##  end
##end
##
p "Done."


