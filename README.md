# Create an Active Directory forest with two domains, and four DCs

This template will create a new Active Directory forest for you, with a 
root and child domain. You can choose between one or two Domain 
Controllers per domain, and you can pick an Operating System version of 
Windows Server 2012, Windows Server 2012 R2, or Windows Server 2016. 

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
Region, so the fact that a dedicated VNET is used is not a connectivity 
limitation anymore. 

The Domain Controllers are placed in an Availability Set to maximize 
uptime. A new storage account is created with an auto-generated name. 
The storage account is of type "Premium" to allow VMs to use fast SSD 
storage. You can pick the replication scope of the storage account. The 
list of VM types is pre-populated with types that are suitable for DCs, 
from very small to large. Be careful, not all combinations of storage 
account type and VM type are possible. Deploy SSD VMs Only to an Premium 
storage account, and "normal" VMs to a non-premium storage account. 

Most template parameters have sensible defaults. You will get a forest 
root of _contoso.com_, a child domain called _child.contoso.com_, two 
DCs in each domain, a small IP space of 10.0.0.0/22 (meaning 10.0.0.0 up 
to 1.0.0.3.255), etc. The VMs are of type DS1_v2, meaning 3.5 GB of 
memory, one core and SSD storage. This is plenty for a simple Active 
Directory. The only thing you really need to do is to supply an admin 
password. Make sure it is 8 characters or more, and complex. You know 
the drill. 

Click the button below to deploy a forest to Azure. 
Expect the whole thing to take about one hour. 

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fwkasdorp%2Fforest-2-domains%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>


### Credits

This project was initially copied from the
 <a href="https://github.com/Azure/azure-quickstart-templates/tree/master/active-directory-new-domain-ha-2-dc"> active-directory-new-domain-ha-2-dc</a> 
project by Simon Davies, part of the the Azure Quickstart templates.

### Tech notes
#### DNS
The hard part about creating forests, domains and Domain Controller in 
Azure is the managing of DNS and DNS references. AD strongly depends on 
its own DNS domains and during domain creation the relevant zones must 
be created. On the other hand, Azure VMs _must_ have internet 
connectivity for its internal Azure Agent to work. 

To meet this requirement, the DNS reference in the IP Settings of each 
VM must be changed a couple of times during deployment. The design 
choice I made was to appoint the first VM as master DNS. It will resolve 
externally, and this is why the configuration asks you to supply an 
external forwarder. In the end situation, the VNET has two DNS servers 
pointing to the forest root domain, so any new VM you add to the VNET 
will have a working DNS allowing it to find the AD zones and the 
internet domains. 

I also had to look carefully at the order in which the VMs are provisioned.
Initially I created the root domain on DC1. Then, I promoted DC2 (root)
and DC3 (child) at the same time. After much testing I discovered that this
would _sometimes_ go wrong because DC3 would take DC2 as a DNS source
when it was not ready. So I reordered the dependencies first promoted DC1 (root), 
then DC3 (child), and only then added secondary DCs to both domains.
These subtle things matter. 

#### Subtemplates
I spent a lot of time factoring this solution to avoid redundancy, 
although I did not fully succeed in this. For repeatable jobs I use 
subtemplates. Creating a new VM is a nice example. 

Subtemplates are also used for simple choices, such as the option to use 
one or two domain controllers. Each choice has its own template file, 
depending on the parameter. For example, these are the two templates 
used for VM creation. The yes/no parameter determines the filename. 

* CreateAndPrepnewVM-no.json
* CreateAndPrepnewVM-yes.json

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
_fabrikam.com_. The DSC for Active Directory does not allow this. 

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
R2. While the standard Azure image supports DSC now, it is still highly 
limited in which modules work or not. This is almost undocumented, but 
the short version is that almost nothing worked so I had to give it up. 


Enjoy, and let me know if you have suggestions or improvements. 

Willem Kasdorp, 3-2-2017. 
