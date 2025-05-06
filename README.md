osl-jenkins Cookbook
====================

Jenkins wrapper cookbook for OSL.

Before testing, make sure you have set all the environment variables needed in `kitchen.yml`.

Use these when creating an OAuth App on GitHub for the GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET variables:

* Homepage URL: `https://10.1.100.100`
* Authorization callback URL: `https://10.1.100.100/securityRealm/finishLogin`

replacing 10.1.100.100 with the IP created by test-kitchen.

When creating a token for GITHUB_TOKEN, the user associated with it must have the Admin role on the test cookbook -
this is required for the webhook permissions needed for the `cookbook-uploader` suite. See
https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/repository-roles-for-an-organization#permissions-for-each-role
for more information.

Requirements
------------
TODO: List your cookbook requirements. Be sure to include any requirements this cookbook has on platforms, libraries, other cookbooks, packages, operating systems, etc.

e.g.
#### packages
- `toaster` - osl-jenkins needs toaster to brown your bagel.

Attributes
----------
TODO: List your cookbook attributes here.

e.g.
#### osl-jenkins::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['osl-jenkins']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

Usage
-----

e.g.
Just include `osl-jenkins` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[osl-jenkins]"
  ]
}
```

Contributing
------------

TODO: (optional) If this is a public cookbook, detail the process for contributing. If this is a private cookbook, remove this section.

e.g.
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors: TODO: List authors
