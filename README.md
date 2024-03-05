# krios-data-mgmt

Scripts used to sync and manage Krios data and notes about the data structure
and syncing/archiving process.

## Data Locations

### Instruments
* Krios1
    * Falcon Server (Primary Data Source)
        * `smb://czii-krios1-falcon/OffLoadData`
    * Replicas
        * `czii-gpu-b-1:datapool/exports/local/instruments/czii.krios1`
            * Mounted locally at `/local/instruments/czii.krios1`
            * Mounted globally at `/hpc/nodes/czii-gpu-b-1/[TO-BE-DETERMINED]`
        * `czii-st-a-1:fastpool/exports/hpc/instruments/czii.krios1`
            * Mounted globally at `/hpc/instruments/czii.krios1`
        * `bruno:/exa1/hpc/instruments/czii.krios1`
            * Mounted globally at `hpc/instruments/czii.krios1`
    * Archive
        * `czii-st-a-1:datapool/exports/hpc/archives/czii.krios1
            * Mounted globally at `/hpc/archives/czii.krios1`
        * `bruno:/exa1/hpc/archives/czii.krios1`
            * Mounted globally at `/hpc/archives/czii.krios1`
    * Deep Archive
        * TO-BE-DETERMINED process for sending old runs to Deep Archive for disaster recovery and long term storage.

## OffloadData Structure

Expected directory structure and archival/cleanup handling process

* OffLoadData


Notes from Anchi

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


