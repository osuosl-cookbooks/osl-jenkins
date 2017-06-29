require 'json'
require 'pry'

@packer_templates_dir = ENV['PACKER_TEMPLATES_DIR'] || './bento/packer'

# Finds what templates are composed of a given script
# @param filename
#
# This is useful to figure out what images should be rebuilt when a 
# composing script is modified
#
# @todo implement a good deep search algorithm not depending on the structure
def find_dependent_templates(composing_script)
  begin
    dependent_templates = []
    
    # go to dir containing all images
    Dir.chdir(@packer_templates_dir)

    # iterate through images and look whether they refer to composing_script
    Dir.glob('*.json') do |t|
      t_data = JSON.load(open(t))
      if t_data.include? 'provisioners' and not t_data['provisioners'].empty?
        if t_data['provisioners'][0].include? 'scripts'
          dependent_templates << t if t_data['provisioners'][0]['scripts'].include? composing_script
        end
      end
    end
  rescue Exception => e
    puts e
  end
  return dependent_templates
end

# Takes github payload and extracts filenames from it
# to further process

def github_payload_processor(payload)
  # if template files in payload
    # add them to the openstack_taster queue
  # if scripts in the payload
    # find the dependent templates (apart from the ones already added)
    # add them to the openstack_taster queue
end
