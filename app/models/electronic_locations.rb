module ElectronicLocations
  # Constants for MARC 856 access method indicators
  # @see https://www.loc.gov/marc/bibliographic/bd856.html
  module Indicators
    NO_INFO = '#'
    EMAIL = '0'
    FTP = '1'
    REMOTE_LOGIN = '2'
    DIAL_UP = '3'
    HTTP = '4'
    SUBFIELD_2 = '7'
  end

  # Constants for MARC 856 relationship indicators
  # @see https://www.loc.gov/marc/bibliographic/bd856.html
  module Relationships
    NO_INFO = '#'
    RESOURCE = '0'
    VERSION = '1'
    RELATED = '2'
    NO_DISPLAY = '3'
  end

  # Constants for MARC 856 subfield codes
  # @see https://www.loc.gov/marc/bibliographic/bd856.html
  module SubfieldCodes
    HOST_NAME = 'a'
    ACCESS_NUMBER = 'b'
    COMPRESSION_INFO = 'c'
    PATH = 'd'
    ELECTRONIC_INFO = 'f'
    PROCESSOR_OF_REQ = 'h'
    INSTRUCTION = 'i'
    BITS_PER_SECOND = 'j'
    PASSWORD = 'k'
    LOGON = 'l'
    CONTACT_ACCESS_ASSIST = 'm'
    NAME_OF_LOCATION_HOST = 'n'
    OPERATION_SYSTEM = 'o'
    PORT = 'p'
    ELECTRONIC_FORMAT_TYPE = 'q'
    SETTINGS = 'r'
    FILE_SIZE = 's'
    TERM_EMULATION = 't'
    URI = 'u'
    HOURS_ACCESS_METHOD = 'v'
    RECORD_CONTROL_NUM = 'w'
    NONPUBLIC_NOTE = 'x'
    LINK_TEXT = 'y'
    PUBLIC_NOTE = 'z'
    ACCESS_METHOD = '2'
    MATERIALS_SPECIFIED = '3'
    LINKAGE = '6'
    FIELD_LINK_SEQ_NUM = '8'
  end
end
