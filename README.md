# krios-data-mgmt

Scripts used to sync and manage Krios data and notes about the data structure
and syncing/archiving process.

## Data Locations

### Instruments
* Krios1
    * Falcon Server: `smb://czii-krios1-falcon/OffLoadData`
        * Mounted on `krios` partition nodes at `/bespoke/krios1.OffloadData/`
    * OffloadData read-only Replicas
        * CZII Storage: `czii-st-a-1:fastpool/exports/hpc/instruments/czii.krios1`
            * Mounted globally at `/hpc/instruments/czii.krios1`
        * Bruno DDN/Lustre: `bruno:/exa1/hpc/instruments/czii.krios1`
            * Mounted globally at `hpc/instruments/czii.krios1`
    * Archives
        * CZII Storage: `czii-st-a-1:datapool/exports/hpc/archives/czii.krios1`
            * Mounted globally at `/hpc/archives/czii.krios1`
        * Bruno DDN/Lustre Storage: `bruno:/exa1/hpc/archives/czii.krios1`
            * Downstream replica/backup of CZII Storage
            * Mounted globally at `/hpc/archives/czii.krios1`
    * Deep Archive
	* TO-BE-DETERMINED process/bucket for sending old runs to Deep Archive for
	  disaster recovery and long term storage.

## OffloadData Structure

A description of what is in Offload data and how it's treated for replication/archival is maintained in [this Google sheet](https://docs.google.com/spreadsheets/d/1-EoGB165vMWeXmMRKvj0JI5k009DWVTHIMwpmo_IFjc/edit#gid=0)


Notes from Anchi

```
Here is the list of path that needs to avoid.  Note that if I say `"folder/*"`,
it means the files within also need to be preserved.  If I say `"folder/"`, it
means the folder needs to be preserved, but its content should be synched and
removed,

* archive/*
* Service/*
* TemScripting/EF-Falcon
* TemScripting/STEM
* serialem-data
* .athena/*
* ImagesForProcessing/*

Please preserve /OffloadData/exportData/Athena_Eported_Datasets/ folder
structure.  Its content should be synced and removed from the camera/athena
server.  We will need to discuss internally if these should be archived.
```

