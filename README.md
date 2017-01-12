# Create a 2 new Windows VMs, create a new AD Forest, Domain and 2 DCs in an availability set

This template will deploy 2 new VMs (along with a new VNet, Storage Account and Load Balancer) and create a new  AD forest and domain, each VM will be created as a DC for the new domain and will be placed in an availability set. Each VM will also have an RDP endpoint added with a public load balanced IP address.

Click the button below to deploy.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fwkasdorp%2Fforest-2-domains%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fwkasdorp%2Fforest-2-domains%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

Credits: project initially copied from <a href="https%3A%2F%2Fgithub.com%2FAzure%2Fazure-quickstart-templates%2Ftree%2Fmaster%2Factive-directory-new-domain-ha-2-dc" target="_blank">

