

## Post install steps:

- Open Administration settings -> Office -- this will initialize the office;  
  To check see if the /Templates directory is populated.
- Update Nextcoud to the latest version via Administration settings, this 
  can take more than one run
- Apply the recommended in Administration settings `occ` commands, usually:
  - `turnkey-occ maintenance:repair --include-expansive`
  - `turnkey-occ db:add-missing-indices`



