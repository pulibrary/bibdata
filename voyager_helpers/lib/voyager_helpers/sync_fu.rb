module VoyagerHelpers
  class SyncFu

# SQL> describe BIB_MASTER;
#  Name            Null?    Type
#  ----------------------------------------- -------- ----------------------------
#  BIB_ID               NUMBER(38)
#  LIBRARY_ID             NUMBER(38)
#  SUPPRESS_IN_OPAC           CHAR(1)
#  CREATE_DATE              DATE
#  UPDATE_DATE              DATE
#  EXPORT_OK              CHAR(1)
#  EXPORT_OK_DATE             DATE
#  EXPORT_OK_OPID             VARCHAR2(10)
#  EXPORT_OK_LOCATION_ID            NUMBER(38)
#  EXPORT_DATE              DATE
#  EXISTS_IN_DPS           NOT NULL CHAR(1)
#  EXISTS_IN_DPS_DATE           DATE


# Note that a MFHD being updated does not change the UPDATE_DATE above. Will need
# to get all holdings added or updated since _t_ and include those bibs as well.


  end # class SyncFu
end # module VoyagerHelpers
