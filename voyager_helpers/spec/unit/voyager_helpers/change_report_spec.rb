require 'spec_helper'
require 'date'

NOW = DateTime.now.new_offset(0)

describe VoyagerHelpers::ChangeReport do

  let(:bib_report) { 
    report = described_class.new()
    report.created =  [
      {
        id: '6',
        lastmod: DateTime.parse('2013-04-12T13:40:57-05:00').new_offset(0)
      }, {
        id: '11',
        lastmod: DateTime.parse('2000-06-08T00:00:00-05:00').new_offset(0)
      }, {
        id: '12',
        lastmod: DateTime.parse('2005-08-08T013:52:00-05:00').new_offset(0)
      }
    ]
    report.updated = [
      {
        id: '1',
        lastmod: DateTime.parse('2012-06-21T11:40:38-05:00').new_offset(0)
      }, {
        id: '8',
        lastmod: DateTime.parse('2012-07-06T10:22:00-05:00').new_offset(0)
      },{
        id: '17',
        lastmod: DateTime.parse('2004-07-08T11:51:00-05:00').new_offset(0)
      }, {
        id: '7',
        lastmod: DateTime.parse('2007-06-09T12:43:24-05:00').new_offset(0)
      }
    ]
    report.deleted = [
      { id: '2', lastmod: NOW },
      { id: '5', lastmod: NOW }
    ]
    report
  }

  let(:holding_report) { 
    report = described_class.new()
    report.created =  [
      {
        id: '106',
        lastmod: DateTime.parse('2013-04-12T13:40:57-05:00').new_offset(0)
      }, {
        id: '1011',
        lastmod: DateTime.parse('2013-04-12T14:40:57-05:00').new_offset(0)
      }, {
        id: '1017',
        lastmod: DateTime.parse('2005-07-08T11:51:00-05:00').new_offset(0)
      }, {
        id: '1018',
        lastmod: DateTime.parse('2007-06-08T11:51:00-05:00').new_offset(0)
      }, {
        id: '1019',
        lastmod: DateTime.parse('2007-06-08T11:53:00-05:00').new_offset(0)
      }, {
        id: '107',
        lastmod: DateTime.parse('2006-06-08T11:51:01-05:00').new_offset(0)
      }, {
        id: '109',
        lastmod: DateTime.parse('2006-06-08T11:52:01-05:00').new_offset(0)
      }

    ]
    report.updated = [
      {
        id: '101',
        lastmod: DateTime.parse('2012-07-06T10:20:00-05:00').new_offset(0)
      }, {
        id: '108',
        lastmod: DateTime.parse('2013-08-06T10:22:00-05:00').new_offset(0)
      }, {
        id: '1012',
        lastmod: DateTime.parse('2005-08-08T14:52:00-05:00').new_offset(0)
      }, {
        id: '1016',
        lastmod: DateTime.parse('2007-04-25T09:41:24-05:00').new_offset(0)
      }
    ]
    report.deleted = [
      { id: '102', lastmod: NOW },
      { id: '105', lastmod: NOW }
    ]
    report
  }

  let(:fake_bib_info) {
    [
      { 
        # in holding.created
        # not in bib
        # should go to updated group with the holding's :lastmod
        id: '15', 
        lastmod: DateTime.parse('2005-01-28T13:40:57-05:00').new_offset(0),
        holding_id: '106'
      },{ 
        # in holding.updated
        # not in bib
        # should go to updated group with the holding's :lastmod
        id: '16', 
        lastmod: DateTime.parse('2007-04-25T09:41:24-05:00').new_offset(0),
        holding_id: '1016'
      },{ 
        # in bib.updated
        # in holding.updated
        # holding is NEWER so should have the holding's lastmod
        id: '1',
        lastmod: DateTime.parse('2012-06-21T11:40:38-05:00').new_offset(0),
        holding_id: '108'
      },{ 
        # in bib.updated
        # in holding.updated
        # holding is (2 min) OLDER so should have the bib's lastmod
        id: '8',
        lastmod: DateTime.parse('2012-07-06T10:22:00-05:00').new_offset(0),
        holding_id: '101'
      },{ 
        # in bib.created
        # in holding.created
        # holding is NEWER so should have the holding's lastmod
        id: '6',
        lastmod: DateTime.parse('2013-04-12T13:40:57-05:00').new_offset(0),
        holding_id: '1011'
      },{ 
        # No bib found; shouldn't be anywhere
        holding_id: '102'
      },{ 
        # in bib.created
        # in holding.updated
        # holding is NEWER so should have the holding's lastmod
        id: '12',
        lastmod: DateTime.parse('2005-08-08T13:52:00-05:00').new_offset(0),
        holding_id: '1012'
      },{ 
        # in bib.updated
        # in holding.created
        # holding is NEWER so should have the holding's lastmod
        id: '17',
        lastmod: DateTime.parse('2004-07-08T11:51:00-05:00').new_offset(0),
        holding_id: '1017'
      }, {
        # This and following:
        # Not in bib
        # in holding.created
        # should have the :lastmod of the second one
        id: '18',
        lastmod: DateTime.parse('2006-06-08T11:51:01-05:00').new_offset(0),
        holding_id: '1018'
      }, 
      {
        id: '18',
        lastmod: DateTime.parse('2006-06-08T11:51:01-05:00').new_offset(0),
        holding_id: '1019'
      }, {
        # This and following:
        # Not in bib.updated
        # in holding.created
        # Bib lastmod is newer
        # should have the :lastmod of the bib
        id: '7',
        lastmod: DateTime.parse('2007-06-09T12:43:24-05:00').new_offset(0),
        holding_id: '107'
      }, 
      {
        id: '7',
        lastmod: DateTime.parse('2007-06-09T12:43:24-05:00').new_offset(0),
        holding_id: '109'
      }
    ]
  }

  let(:merged_report) { 
    report = described_class.new()
    report.created =  [
      {
        id: '6',
        lastmod: DateTime.parse('2013-04-12T14:40:57-05:00').new_offset(0)
      }, {
        id: '11',
        lastmod: DateTime.parse('2000-06-08T00:00:00-05:00').new_offset(0)
      }, {
        id: '12',
        lastmod: DateTime.parse('2005-08-08T14:52:00-05:00').new_offset(0)
      }
    ]
    report.updated = [
      {
        id: '1',
        lastmod: DateTime.parse('2013-08-06T10:22:00-05:00').new_offset(0)
      }, {
        id: '8',
        lastmod: DateTime.parse('2012-07-06T10:22:00-05:00').new_offset(0)
      }, {
        id: '17',
        lastmod: DateTime.parse('2005-07-08T11:51:00-05:00').new_offset(0)
      }, {
        id: '7',
        lastmod: DateTime.parse('2007-06-09T12:43:24-05:00').new_offset(0)
      }, {
        id: '15',
        lastmod: DateTime.parse('2013-04-12T13:40:57-05:00').new_offset(0)
      }, {
        id: '16', 
        lastmod: DateTime.parse('2007-04-25T09:41:24-05:00').new_offset(0)
      }, {
        id: '18',
        lastmod: DateTime.parse('2007-06-08T11:53:00-05:00').new_offset(0)
      }
    ]
    report.deleted = [
      { id: '2', lastmod: NOW },
      { id: '5', lastmod: NOW }
    ]
    report
  }

  describe 'merge_in_holding_report' do
    it 'merges as expected' do
      bib_report.merge_in_holding_report(holding_report, fake_bib_info)
      expect(bib_report.created).to eq merged_report.created
      expect(bib_report.updated).to eq merged_report.updated
      expect(bib_report.deleted).to eq merged_report.deleted
    end
  end

  describe 'to_a' do
    it 'sorts earliest to latest' do
      expected =  [
        {
          change: :created,
          id: '11',
          lastmod: DateTime.parse('2000-06-08T00:00:00-05:00').new_offset(0)
        }, {
          change: :updated,
          id: '17',
          lastmod: DateTime.parse('2004-07-08T11:51:00-05:00').new_offset(0)
        }, {
          change: :created,
          id: '12',
          lastmod: DateTime.parse('2005-08-08T013:52:00-05:00').new_offset(0)
        }, {
          change: :updated,
          id: '7',
          lastmod: DateTime.parse('2007-06-09T12:43:24-05:00').new_offset(0)
        }, {
          change: :updated,
          id: '1',
          lastmod: DateTime.parse('2012-06-21T11:40:38-05:00').new_offset(0)
        }, {
          change: :updated,
          id: '8',
          lastmod: DateTime.parse('2012-07-06T10:22:00-05:00').new_offset(0)
        }, {
          change: :created,
          id: '6',
          lastmod: DateTime.parse('2013-04-12T13:40:57-05:0').new_offset(0)
        },{
          change: :deleted,
          id: '2',
          lastmod: NOW
        }, {
          change: :deleted,
          id: '5',
          lastmod: NOW
        }
      ]
      expect(bib_report.to_a).to eq expected
    end # it 'sorts earliest to latest'
  end # describe 'to_a'

  describe 'all_ids' do
    it 'returns all ids as an array' do
      expected = ['6', '11', '12', '1', '8', '17', '7', '2', '5']
      expect(bib_report.all_ids).to eq expected
    end
  end # describe 'all_ids' 

end # describe VoyagerHelpers::ChangeReport
