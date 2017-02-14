# OpenLDAP
## Introduction to OpenLDAP Directory Services
### What is a directory service?
A directory is a specialized database specifically designed for searching and browsing, in additional to supporting basic lookup and update functions.

### What is LDAP?
LDAP stands for Lightweight Directory Access Protocol. As the name suggests, it is a lightweight protocol for accessing directory services

This section gives an overview of LDAP from a user's perspective.

*What kind of information can be stored in the directory?* The LDAP information model is based on *entries*. An entry is a collection of attributes that has a globally-unique Distinguished Name (DN). The DN is used to refer to the entry unambiguously. Each of the entry's attributes has a *type* and one or more *values*. The types are typically mnemonic strings, like "`cn`" for common name, or "`mail`" for email address. The syntax of values depend on the attribute type. For example, a `cn` attribute might contain the value `Babs Jensen`. A `mail` attribute might contain the value "`babs@example.com`". A `jpegPhoto` attribute would contain a photograph in the JPEG (binary) format.

*How is the information arranged?* The tree may be arranged based upon Internet domain names.
![LDAP directory tree (Internet naming)](https://github.com/wangchenghku/COLO/blob/master/apps/ldap/intro_dctree.png)

### What is slapd and what can it do?
*slapd* is an LDAP directory server.

**Choice of database backends:** *slapd* comes with a variety of different database backends you can choose from. They include BDB, a high-performance transactional database backend.

## A Quick-Start Guide

1. **Add initial entries to your directory.**
You can use ldapadd to add entries to your LDAP directory. ldapadd expects input in LDIF form. We'll do it in two steps:

   1.1 create an LDIF file

   1.2 run ldapadd

   Use your favorite editor and create an LDIF file that contains:
   ```
   dn: dc=<MY-DOMAIN>,dc=<COM>
   objectclass: dcObject
   objectclass: organization
   o: <MY ORGANIZATION>
   dc: <MY-DOMAIN>

   dn: cn=Manager,dc=<MY-DOMAIN>,dc=<COM>
   objectclass: organizationalRole
   cn: Manager
   ```
   Be sure to replace `<MY-DOMAIN>` and `<COM>` with the appropriate domain components of your domain name. `<MY ORGANIZATION>` should be replaced with the name of your organization.

   ```
   dn: dc=example,dc=com
   objectclass: dcObject
   objectclass: organization
   o: Example Company
   dc: example

   dn: cn=Manager,dc=example,dc=com
   objectclass: organizationalRole
   cn: Manager
   ```

   Now, you may run *ldapadd* to insert these entries into your directory.
   ```
   ldapadd -x -D "cn=Manager,dc=<MY-DOMAIN>,dc=<COM>" -W -f example.ldif
   ```

   Be sure to replace `<MY-DOMAIN>` and `<COM>` with the appropriate domain components of your domain name.
   ```
   ldapadd -x -D "cn=Manager,dc=example,dc=com" -W -f example.ldif
   ```
