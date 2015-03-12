require 'traject/macros/marc21_semantics'
require './lib/umich_format/xv6xx'


# Determine the "types" of material represented by the bib record.
# The comments below come from the Ex Libris Aleph system and represent
# the logic used within it to determine types. This file is based
# on the logic use at the University of Michigan

class BibTypes

  attr_reader :bib_format, :record

  def initialize(bib_format, record)
    @bib_format = bib_format
    @record = record
    # Memoize values, since many of them are used several times
    @spec_vals  = Hash.new { |h, spec_string| h[spec_string] = Traject::MarcExtractor.new(spec_string).extract(@record) }

    # Need these a lot -- the sub x and v from any 6XX field
    @xv6XX      = XV6XX.new(@record)
  end
  
  
  def codes
    codes = []
    codes.concat self.video_types
    codes.concat self.audio_types
    codes.concat self.microform_types
    codes.concat self.musical_score_types
    codes.concat self.map_types
    codes.concat self.serial_types
    codes.concat self.mixed_types
    codes.concat self.software_types
    codes.concat self.statistics_types
    codes.concat self.conference_types
    codes.concat self.biography_types
    codes.concat self.reference_types
    codes.concat self.pp_types
    codes.concat self.videogame_types

    codes.uniq!
    codes.compact!
    
    codes
  end
    
  

  # Provide memoized values for on-the-fly created MarcExtractor
  # objects
  #
  # @param [String] spec_string A Traject::MarcExtractor-compatible spec string
  # @return [Array<String>] The strings in the specified subfields/byterange/whatever
  def [](spec_string)
    @spec_vals[spec_string]
  end


  ### Video stuff

  # TYP   VB Video (Blu-ray)                538## a          MATCH      *Blu-ray*
  # TYP   VB Video (Blu-ray)                007   F00-05     MATCH      v???s
  # TYP   VB Video (Blu-ray)                250## a          MATCH      *Blu-ray*
  # TYP   VB Video (Blu-ray)                852## j          MATCH      video-b*
  # TYP   VB Video (Blu-ray)                852## j          MATCH      bd-rom*
  #
  # TYP   VD Video (DVD)                    538## a          MATCH      DVD*
  # TYP   VD Video (DVD)                    007   F04-01     EQUAL      v
  #                                         007   F00-01     EQUAL      v
  # TYP   VD Video (DVD)                    007   F04-01     EQUAL      v
  #                                         008   F33-01     EQUAL      v
  # !
  # ! Visual material: vHs
  # TYP   VH Video (VHS)                    538## a          MATCH      VHS*
  # TYP   VH Video (VHS)                    007   F04-01     EQUAL      b
  #                                         007   F00-01     EQUAL      v
  # TYP   VH Video (VHS)                    007   F04-01     EQUAL      b
  #                                         008   F33-01     EQUAL      v
  # !
  # ! Visual materials: fiLm/video
  # TYP   VL Motion Picture                 007   F00-01     EQUAL      m
  # TYP   VL Motion Picture                 FMT   F00-02     EQUAL      VM
  #                                         008   F33-01     EQUAL      m

  def video_types
    types = []

    types << 'VB' if self['538a:250a'].grep(/blu-ray/i).size > 0
    types << 'VB' if self['007[0-5]'].grep(/v...s/i).size > 0
    types << 'VB' if self['852j'].grep(/\A(?:bd-rom|video-b)/i).size > 0

    @record.fields('007').map{|f| f.value}.each do |f|
      if (f[0] == 'v') || self['008[33]'].include?('v')
        types << 'VD' if f[4] == 'v'
        types << 'VH' if f[4] == 'b'
      end
    end


    types << 'VD' if self['538a'].grep(/\Advd(?!\-rom)/i).size > 0

    types << 'VH' if self['538a'].grep(/\AVHS/i).size > 0


    types << 'VL' if self['007[0]'].include?('m')
    types << 'VL' if (self.bib_format == 'VM') && self['008[33]'].include?('m')

    types.uniq!
    return types
  end


  # Audio/music
  # ! Recording: Compact disc
  # TYP   RC Audio CD                       LDR   F06-01     EQUAL      [i,j]
  #                                         FMT   F00-02     EQUAL      MU
  #                                         007   F01-01     EQUAL      d
  #                                         007   F12-01     EQUAL      e
  # TYP   RC Audio CD                       8524  j          MATCH      CD*
  #                                         8524  b          EQUAL      MUSIC
  # !
  # ! Recording: LP record
  # TYP   RL Audio LP                       LDR   F06-01     EQUAL      [i,j]
  #                                         FMT   F00-02     EQUAL      MU
  #                                         007   F01-01     EQUAL      d
  #                                         300   a          MATCH      *SOUND DISC*
  #                                         300   b          MATCH      *33 1/3 RPM*
  #
  # TYP   RL Audio LP                       8524  j          MATCH      LP*
  #                                         8524  c          EQUAL      MUSI
  # TYP   RL Audio LP                       8524  j          MATCH      LP*
  #                                         8524  b          EQUAL      MUSIC
  # !
  # ! Recording: Music
  # TYP   RM Audio (music)                  LDR   F06-01     EQUAL      j
  #                                         FMT   F00-02     EQUAL      MU
  # !
  # ! Recording: Spoken word
  # TYP   RS Audio (spoken word)            LDR   F06-01     EQUAL      i
  #                                         FMT   F00-02     EQUAL      MU
  # !
  # ! Recording: Undefined
  # TYP   RU Audio                          LDR   F06-01     EQUAL      [i,j]
  #                                         FMT   F00-02     EQUAL      MU
  #

  def audio_types
    ldr6 = record.leader[6]

    types = []

    # Get the 8524* fields
    f8524 = record.fields('852').select{|f| f.indicator1 == '4'}

    # RC
    if %w[i j].include?(ldr6) && (bib_format == 'MU') 
      @record.fields('007').map{|f| f.value}.each do |f|
        if f[1] == 'd' && f[12] == 'e'
          types << 'RC'
          break
        end
      end
    end

    f8524.each do |f|
      if (f['b'].upcase == 'MUSIC') && (f['j'] =~ /\ACD/i)
        types << 'RC'
        break
      end
    end

    # RL

    if  (bib_format == 'MU') && %w[i j].include?(ldr6) && self['007[1]'].include?('d')
      record.fields('300').each do |f|
        str = f.subfields.collect {|s| s.value}.join(' ')
        if (str =~ /DISC/i) && str =~ /33 1\/3 RPM/i
          types << 'RL'
          break
        end
      end
    end


    f8524.each do |f|
      if  (f['j'] =~ /\ALP/i) &&
          ((f['b'].upcase == 'MUSIC') || (f['c'].upcase == 'MUSI'))
        types << 'RL'
        break
      end
    end

    # RM
    types << 'RM' if (ldr6 == 'j') && (bib_format == 'MU')

    # RS
    types << 'RS' if (ldr6 == 'i') && (bib_format == 'MU')

    # RU
    types << 'RU' if %w[i j].include?(ldr6) && (bib_format == 'MU')

    types.uniq!
    return types
  end


  # Microform
  # ! MicroForms
  # TYP   WM Microform                      FMT   F00-02     EQUAL      BK
  #                                         008   F23-01     EQUAL      [a,b,c]
  # TYP   WM Microform                      FMT   F00-02     EQUAL      MU
  #                                         008   F23-01     EQUAL      [a,b,c]
  # TYP   WM Microform                      FMT   F00-02     EQUAL      SE
  #                                         008   F23-01     EQUAL      [a,b,c]
  # TYP   WM Microform                      FMT   F00-02     EQUAL      MX
  #                                         008   F23-01     EQUAL      [a,b,c]

  # TYP   WM Microform                      245## h          MATCH      *micro*

  # TYP   WM Microform                      FMT   F00-02     EQUAL      MP
  #                                         008   F29-01     EQUAL      [a,b,c]
  # TYP   WM Microform                      FMT   F00-02     EQUAL      VM
  #                                         008   F29-01     EQUAL      [a,b,c]

  def microform_types
    return [] unless record['008']
    types = ['WM']
    f8_23 = record['008'].value[23]
    return types if %w[BK MU SE MX].include?(bib_format) && %w[a b c].include?(f8_23)

    f8_29 = record['008'].value[29]
    return types if %w[MP VM].include?(bib_format) &&  %w[a b c].include?(f8_29)

    return types if record['245'] && (record['245']['h'] =~ /micro/i)

    # Nope. Not microform
    return []
  end


  # ! Musical Score
  # TYP   MS Musical Score                  LDR   F06-01     EQUAL      [c,d]

  def musical_score_types
    types = []
    types << 'MS' if %w[c d].include?(record.leader[6])
    return types
  end


  # ! Maps: Numerous
  # TYP   MN Maps-Atlas                     FMT   F00-02     EQUAL      MP
  # TYP   MN Maps-Atlas                     LDR   F06-01     EQUAL      [e,f]
  # TYP   MN Maps-Atlas                     007   F00-01     EQUAL      a
  # !
  # ! Maps: One (commented out as per Judy Ahronheim as this TYP duplicates MN)
  # !TYP   MO Map                            FMT   F00-02     EQUAL      MP
  # !TYP   MO Map                            007   F00-01     EQUAL      a


  def map_types
    types = []
    if (bib_format == 'MP') || %w[e f].include?(record.leader[6]) ||  self['007[0]'].include?('a')
      types << 'MN'
    end
    return types
  end


  # Serials
  # ! serial: A Journal
  # TYP   AJ Journal                        FMT   F00-02     EQUAL      SE
  #                                         008   F21-01     EQUAL      p
  #                                         008   F22-01     EQUAL      [^,a,b,c,d,f,g,h,i,s,x,z,|]
  #                                         008   F29-01     EQUAL      [0,|]
  # TYP   AJ Journal                        FMT   F00-02     EQUAL      SE
  #                                         008   F21-01     EQUAL      [^,d,l,m,p,w,|]
  #                                         008   F22-01     EQUAL      [^,a,b,c,d,f,g,h,i,s,x,z,|]
  #                                         008   F24-01     EQUAL      [a,b,g,m,n,o,p,s,w,x,y,^]
  #                                         008   F29-01     EQUAL      [0,|]
  # !
  # ! serial: A Newspaper
  # TYP   AN Newspaper                      FMT   F00-02     EQUAL      SE
  #                                         008   F21-01     EQUAL      n
  # TYP   AN Newspaper                      FMT   F00-02     EQUAL      SE
  #                                         008   F22-01     EQUAL      e
  #
  # ! serial: All, including serials with other FMT codes
  # TYP   SX All Serials                    LDR   F07-01     EQUAL      [b,s]


  # Wrap it all up in serial_types
  def serial_types
    types = []
    types << 'SX' if %w[b s].include?(record.leader[7])
    types.concat journal_types
    types.concat newspaper_types
    types.uniq!
    return types
  end


  def journal_types

    types = []
    # gotta be SE and have a 008
    return types unless (bib_format == 'SE') && record['008']


    # We need lots of chars from the 008
    f8 = record['008'].value

    if  (f8[21] == 'p') &&
        [' ','a','b','c','d','f','g','h','i','s','x','z','|'].include?(f8[22]) &&
        ['0', '|'].include?(f8[29])
      types << 'AJ'
    end

    if  [' ','d','l','m','p','w','|'].include?(f8[21]) &&
        [' ','a','b','c','d','f','g','h','i','s','x','z','|'].include?(f8[22]) &&
        ['a','b','g','m','n','o','p','s','w','x','y',' '].include?(f8[24]) &&
        ['0', '|'].include?(f8[29])
      types << 'AJ'
    end

    types.uniq!
    return types
  end

  def newspaper_types
    types = []
    types << 'AN' if (bib_format == 'SE') && record['008'] &&
        ((record['008'].value[21] == 'n') || (record['008'].value[22] == 'e'))
    return types
  end


  # ! Mixed material: archi-V-e
  # TYP   MV Archive                        FMT   F00-02     EQUAL      MX
  # TYP   MV Archive                        LDR   F08-01     EQUAL      a
  # !
  # ! Mixed material: manuscript
  # TYP   MW Manuscript                     LDR   F06-01     EQUAL      [d,f,p,t]

  def mixed_types
    types = []
    types << 'MV' if (bib_format == 'MX') || (record.leader[8] == 'a')
    types << 'MW' if %w[d f p t].include?(record.leader[6])
    return types
  end

  # TYP   CR CDROM                          852## j          MATCH      cd-rom*
  # TYP   CR CDROM                          852## j          MATCH      cdrom*
  # TYP   CR CDROM                          852## j          MATCH      cd-rom*
  # TYP   CS Software                       852## j          MATCH      software*

  def software_types
    types = []
    self['852j'].each do |j|
      if j =~ /\Acd-?rom/i
        types << 'CR'
      end
      if j =~ /\Asoftware/i
        types << 'CS'
      end
    end
    types.uniq!
    return types
  end

  # ! X (no icon) - Conference
  # TYP   XC Conference                     008   F29-01     EQUAL      1
  # TYP   XC Conference                     111##            EXIST
  # TYP   XC Conference                     711##            EXIST
  # TYP   XC Conference                     811##            EXIST
  # TYP   XC Conference                     FMT   F00-02     EQUAL      CF
  #                                         006   F00-01     EQUAL      [a,s]
  #                                         006   F12-01     EQUAL      1
  # TYP   XC Conference                     FMT   F00-02     EQUAL      MU
  #                                         008   F30-01     EQUAL      c
  # TYP   XC Conference                     FMT   F00-02     EQUAL      MU
  #                                         008   F31-01     EQUAL      c
  # ! additional types defined for vufind extract
  # TYP   XC Conference                     6#### xv         MATCH      *congresses*

  def conference_types
    # Get the easy stuff done first

    return ['XC'] if  (record['008'] && (record['008'].value[29] == '1')) || record.fields(['111', '711', '811']).size > 0

    if  (bib_format == 'CF')
      @record.fields('006').map{|f| f.value}.each do |f|
        return ['XC'] if  %w[a s].include?(f[0]) && (f[12] == '1')
      end
    end

    if  (bib_format == 'MU') && record['008'] &&
        (record['008'].value[30..31] =~ /c/)
      return ['XC']
    end

    return ['XC'] if @xv6XX.match? /congresses/i

    # Nope.
    return []
  end

  # ! X (no icon) - Statistics
  # TYP   XS Statistics                     650## x          MATCH      Statistic*
  # TYP   XS Statistics                     6#### x          MATCH      Statistic*
  # TYP   XS Statistics                     6#### v          MATCH      Statistic*
  # TYP   XS Statistics                     FMT   F00-02     EQUAL      BK
  #                                         008   F24-01     EQUAL      s
  # TYP   XS Statistics                     FMT   F00-02     EQUAL      BK
  #                                         008   F25-01     EQUAL      s
  # TYP   XS Statistics                     FMT   F00-02     EQUAL      BK
  #                                         008   F26-01     EQUAL      s
  # TYP   XS Statistics                     FMT   F00-02     EQUAL      BK
  #                                         008   F27-01     EQUAL      s


  def statistics_types

    if bib_format == 'BK'
      return ['XS'] if record['008'] && record['008'].value[24..27] =~ /s/
    end

    return ['XS'] if @xv6XX.match? /\AStatistic/i

    # Nope
    return []
  end



  # TYP   EN Encyclopedias                  6#### xv         MATCH      *encyclopedias*
  # TYP   EN Encyclopedias                  008   F24-01     EQUAL      e
  # TYP   EN Encyclopedias                  006   F07-01     EQUAL      e
  #
  # TYP   DI Dictionaries                   6#### xv         MATCH      *dictionaries*
  # TYP   DI Dictionaries                   008   F24-01     EQUAL      d
  # TYP   DI Dictionaries                   006   F07-01     EQUAL      d
  #
  # TYP   DR Directories                    6#### xv         MATCH      *directories*
  # TYP   DR Directories                    008   F24-01     EQUAL      r
  # TYP   DR Directories                    006   F07-01     EQUAL      d

  def reference_types
    types = []

    # Will need the 008[24] and 006[7]
    f8_24 =  self['008[24]']
    f6_7 = self['006[7]']



    if (f8_24.include? 'e') || (f6_7.include? 'e')
      types << 'EN'
    end

    if f6_7.include? 'd'
      types << 'DI'
      types << 'DR'
    end

    if f8_24.include? 'd'
      types << 'DI'
    end

    if f8_24.include? 'r'
      types << 'DR'
    end

    types << 'EN' if @xv6XX.match? /encyclopedias/i
    types << 'DI' if @xv6XX.match? /dictionaries/i
    types << 'DR' if @xv6XX.match? /directories/i

    types.uniq!
    return types
  end


  # TYP   BI Biography                      6#### xv         MATCH      *biography*
  # TYP   BI Biography                      6#### xv         MATCH      *diaries*
  # TYP   BI Biography                      008   F34-01     EQUAL      [a,b,c]
  # TYP   BI Biography                      006   F17-01     EQUAL      [a,b,c]

  def biography_types
    return ['BI'] if record['008'] && %w[a b c].include?(record['008'].value[34])
    return ['BI'] if (%w[a b c ] & self['006[17]']).size > 0

    return ['BI'] if @xv6XX.match? /(?:biography|diaries)/i

    # Nope
    return []
  end


  # TYP   PP Photographs & Pictorial Works  6#### xv         MATCH      pictorial works
  # TYP   PP Photographs & Pictorial Works  6#### xv         MATCH      views
  # TYP   PP Photographs & Pictorial Works  6#### xv         MATCH      photographs
  # TYP   PP Photographs & Pictorial Works  6#### xv         MATCH      in art
  # TYP   PP Photographs & Pictorial Works  6#### xv         MATCH      aerial views
  # TYP   PP Photographs & Pictorial Works  6#### xv         MATCH      aerial photographs
  # TYP   PP Photographs & Pictorial Works  6#### xv         MATCH      art
  # TYP   PP Photographs & Pictorial Works  6#### xv         MATCH      cariacatures and cartoons
  # TYP   PP Photographs & Pictorial Works  6#### xv         MATCH      comic books
  # TYP   PP Photographs & Pictorial Works  6#### xv         MATCH      illustrations
  # TYP   PP Photographs & Pictorial Works  6#### xv         MATCH      drawings
  # TYP   PP Photographs & Pictorial Works  6#### xv         MATCH      slides

  class << self
    attr_accessor :pp_regexp
  end

  self.pp_regexp = Regexp.union [ 'pictorial works',
                                  'views',
                                  'photographs',
                                  'in art',
                                  'aerial views',
                                  'aerial photographs',
                                  'cariacatures and cartoons',
                                  'comic books',
                                  'illustrations',
                                  'drawings',
                                  'slides',
                                ].map{|s| Regexp.new('\b'+s+'\b', true)}
  self.pp_regexp = Regexp.union(self.pp_regexp, /\bart\b/i)

  def pp_types
    if @xv6XX.match? self.class.pp_regexp
      return ['PP']
    else
      return []
    end
  end



  # TYP   VG Video Games                    FMT   F00-02     EQUAL      CF
  #                                         008   F26-01     EQUAL      g

  def videogame_types
    if (bib_format == 'CF') && (self['008[26]'].include? 'g')
      return ['VG']
    else
      return []
    end
  end


end
