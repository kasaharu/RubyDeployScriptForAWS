require 'aws-sdk'
require 'dotenv'
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



INSTANCE_NAME        = "appServer_newInstnce"
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
`cat nodes/template.json > nodes/#{@instance_pub_ip_addr}.json`
`knife solo cook -i #{SSH_KEY_FILE_PATH} #{REMOTE_USER}@#{@instance_pub_ip_addr}`


p "Finished chef."


############################## Createing AMI

ami_name = "#{@new_instance.id}_#{DateTime.now.strftime("%Y%m%d%H%M%S")}"
ami_description = "Web Server Base AMI(#{@new_instance.tags['Name']}) at #{DateTime.now}"
new_created_ami = @new_instance.create_image(ami_name, {description: ami_description, no_reboot: true})
@ec2.tags.create(new_created_ami, NAME_TAG, value: "Base_AMI_#{DateTime.now.strftime("%Y%m%d")}")
p "AMI is Created!!!"





p "Done."


