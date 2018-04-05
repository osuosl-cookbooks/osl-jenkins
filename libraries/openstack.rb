module OSLOpenStack
  module Helper
    def add_openstack_cloud
      <<-EOH.gsub(/^ {8}/, '')
        import jenkins.plugins.openstack.compute.*
        import jenkins.model.*
        import hudson.model.*;

        def instance = Jenkins.getInstance()

        JCloudsSlaveTemplate template = new JCloudsSlaveTemplate(
          "template",
          "label",
          new SlaveOptions(
              "img",
              "hw",
              "nw",
              "ud",
              1,
              "public",
              "sg",
              "az",
              2,
              "kp",
              3,
              "jvmo",
              "fsRoot",
              "cid",
              JCloudsCloud.SlaveType.JNLP,
              4
          )
        );
        JCloudsCloud cloud = new JCloudsCloud(
          "osl-openstack", // name for the openstack cloud
          "identity", // format: TENANT_NAME:USER_NAME
          "credential", //password for the username
          "endPointUrl", //OpenStack Auth URL
          "zone",
          new SlaveOptions(
                 "IMG", //Image
                 "HW",
                 "NW",
                 "UD",
                 6,
                 null,
                 "SG",
                 "AZ",
                 7,
                 "KP",
                 8,
                 "JVMO",
                 "FSrOOT",
                 "CID",
                 JCloudsCloud.SlaveType.SSH,
                 9
          ),
          Arrays.asList(template)
        );

        instance.clouds.add(cloud);
      EOH
    end
  end
end
