# Create an Active Directory forest with 1 or 2 domains, each with 1 or 2 DCs

Use this to deploy from Azure Quicktemplates:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2F301-create-ad-forest-with-subdomain%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Click the button below to deploy a forest to Azure using the templates in this Repo:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fwkasdorp%2Fforest-2-domains%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Warning: this template will **create running VMs**. 
Be sure to deallocate them when you no longer need them
to avoid incurring costs.

This template creates an Active Directory forest for you. The configuration
is flexible. 

* The root domain is always created; the child domain is optional. 
* Choose to have one or two DCs per domain.
* Choose names for the Domains, DCs, and network objects.  
* Choose the VM type from a prepopulated list. 
* Use either Windows Server 2012, Windows Server 2012 R2, or Windows Server 2016. 
* Get a public IP endpoint to use with RDP, configured with a Network Security Group.

A forest with two domains in Azure is especially useful for AD-related 
development, testing, and troubleshooting. Many enterprises have complex 
Active Directories with multiple domains, so if you are developing an 
application for such companies it makes a lot of sense to use a 
multi-domain Active Directory as well. 

The template creates a new VNET created with a dedicated subnet for the 
Domain Controllers. A network security group (NSG) is added to limit 
incoming traffic allowing only Remote Desktop Protocol (RDP). You can 
edit the NSG manually to permit traffic from your datacenters only. With 
VNET peering it is easy to connect different VNETs in the same Azure 
Region, so the fact that a dedicated VNET is used here is not a 
connectivity limitation anymore.

The Domain Controllers are placed in an Availability Set to maximize 
uptime. Each domain has its own Availability set. 
The VMs are provisioned with managed disks. The disk type (Standard or Premium)
is derived from the VM size. If the name contains "DS", a Premium (SSD) 
disk used. Otherwise, a Standard (HDD) type is used.

Most template parameters have sensible defaults. You will get a forest 
root of _contoso.com_, a child domain called _child.contoso.com_, two 
DCs in each domain, a small IP space of 10.0.0.0/22 (meaning 10.0.0.0 up 
to 10.0.3.255), etc. Each VM will have the AD-related management tools installed.
By default, the VMs are of type DS1_v2, meaning 3.5 GB of 
memory, one core and SSD storage. This is plenty for a simple Active 
Directory. The only thing you really need to do is to supply an admin 
password. Make sure it is 8 characters or more, and complex. You know 
the drill. 

### Credits

This project was initially copied from the
[active-directory-new-domain-ha-2-dc](https://github.com/Azure/azure-quickstart-templates/tree/master/active-directory-new-domain-ha-2-dc)
project by Simon Davies, part of the the Azure Quickstart templates.

### Tech notes
#### DNS
The hard part about creating forests, domains and Domain Controllers in 
Azure is the managing of DNS Domains and zones, and DNS references. AD strongly depends on 
its own DNS domains, and during domain creation the relevant zones must 
be created. On the other hand, Azure VMs _must_ have internet 
connectivity for their internal Azure Agent to work. 

To meet this requirement, the DNS reference in the IP Settings of each 
VM must be changed a couple of times during deployment. The design 
choice I made was to appoint the first VM as master DNS server. It will resolve 
externally, and this is why the configuration asks you to supply an 
external forwarder. In the end situation, the VNET has two DNS servers 
pointing to the forest root domain, so any new VM you add to the VNET 
will have a working DNS allowing it to find the AD zones and the 
internet domains. 

I also had to look carefully at the order in which the VMs are provisioned.
Initially I created the root domain on DC1. Then, I promoted DC2 (root)
and DC3 (child) at the same time. After much testing I discovered that this
would _sometimes_ go wrong because DC3 would take DC2 as a DNS source
when it was not ready. So I reordered the dependencies to first promote
 DC1 (root), then DC3 (child), and only then add secondary DCs to both domains. 

#### Subtemplates
I spent a lot of time factoring this solution to avoid redundancy, 
although I did not fully succeed in this. For repeatable jobs I use 
subtemplates. Creating a new VM is a nice example. 

In the October 2017 update I greatly simplified the use
of subtemplates. Using the ARM "condition()" function it's now
possible to make deployments optional based on input parameters. 
Using this, it is no longer needed to use two subtemplates for every 
input choice.

#### Desired State Configuration (DSC)

The main requirement when I started this project was that I wanted a 
one-shot template deployment of a working forest without additional 
post-configuration. Clearly, to create an AD forest you must do stuff 
inside all VMs, and different stuff depending on the domain role. I saw 
two ways to accomplish this: script extensions and DSC. 

After some consideration I decided to use DSC to re-use whatever 
existing IP is out there, and to avoid having to develop everything 
myself. Less did I realize that this also means that I have accept the 
limitations that go along with it: if the DSC module does not support 
it, you can't have it. One such example is creation of a tree domain in 
the same forest, such as a root of _contoso.com_ and another tree of 
_fabrikam.com_. The DSC for Active Directory does not currently (feb 2017)
allow this. 

In this project I have only used widely accepted DSC modules to avoid 
developing or maintaining my own: 

* xActivedirectory
* xNetworking
* xDisk
* cDisk

If you look into the DSC Configurations that I use you will see that I 
had to add a Script resource to set the DNS forwarder. This is 
unfortunate (a hack) but the xDNSServer DSC module did not work for me. 
Apparently the DNS service is not stable enough directly after 
installation to support this module. I added a wait loop to solve this 
issue. 

Finally, I had to use an external script resource to enable the 
Powershell execution policy specifically for Windows Server 2012 
(non-R2). By default, DSC does not work here. I injected a small 
powershell script to set the execution policy to unrestricted. 

For similar reasons, this template does not support Windows Server 2008 
R2. While the standard Azure image VM image for 2008 R2
 supports DSC now, it is still highly limited in which modules work or not. 
This is almost undocumented, but the short version is that almost
 nothing worked for 2008 R2 so I had to give it up. 

### Update October 2017

New features:

* Converted VMs to use managed disks.
* Removed the storage account.
* Made the child domain optional.
* Greatly simplified the optional parts of the template using the new "condition" keyword.

### Update September 2018

New Features:

* Added B-series VM.

Willem Kasdorp, 9-17-2017.

`Tags: active directory,forest,domain,DSC`
