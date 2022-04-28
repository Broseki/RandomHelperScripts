# CertTool

This is a tool that I use to generate SSL certificates and basic Nginx configs for services I run in my own house. Generally the use case is I have a docker container that I want to front with a reverse proxy.

I use this script to generate the CSR, then I have my internal CA issue a cert that I paste in, then I give a local port to proxy using that cert. That is pretty much it, but this saves a ton of time.
