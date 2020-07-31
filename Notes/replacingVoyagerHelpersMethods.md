Replacing VoyagerHelpers call methods to voyager
List methods:
VoyagerHelpers::Liberator.get_current_issues(mfhd_serial) unless mfhd_serial.nil?
VoyagerHelpers::Liberator.get_full_mfhd_availability(mfhd) unless mfhd.nil?
VoyagerHelpers::Liberator.get_availability(bib_ids, full)
VoyagerHelpers::Liberator.get_records_from_barcode(sanitize(params[:barcode]), true)
VoyagerHelpers::Liberator.get_records_from_barcode(sanitize(params[:barcode]))
VoyagerHelpers::Liberator.get_bib_record(bib_id_param, nil, opts)
VoyagerHelpers::Liberator.get_bib_record(sanitize(params[:bib_id]), nil, opts)
VoyagerHelpers::Liberator.get_holding_records(sanitize(params[:bib_id]))
VoyagerHelpers::Liberator.get_items_for_bib(bib_id_param)
VoyagerHelpers::Liberator.get_bib_record(id, nil, opts)
VoyagerHelpers::Liberator.get_locations
VoyagerHelpers::Liberator.active_courses
VoyagerHelpers::Liberator.course_bibs(@reserve_ids)
VoyagerHelpers::Liberator.get_holding_record(sanitize(params[:holding_id]))
VoyagerHelpers::Liberator.get_items_for_holding(sanitize(params[:holding_id]))
VoyagerHelpers::Liberator.get_item(sanitize(params[:item_id]))
VoyagerHelpers::Liberator.get_patron_info(sanitize(params[:patron_id]))
VoyagerHelpers::Liberator.get_patron_stat_codes(sanitize(params[:patron_id]))
VoyagerHelpers::Liberator.valid_xml(xml_str)
VoyagerHelpers::Liberator.valid_xml(records.to_xml.to_s)
VoyagerHelpers::Liberator.dump_bibs_to_file(id_slice, df.path)
VoyagerHelpers::Liberator.dump_merged_records_to_file(barcode_slice, df.path, true)
VoyagerHelpers::SyncFu.compare_id_dumps(earlier_p, later_p)
VoyagerHelpers::Liberator.get_updated_bibs(timestamp)
VoyagerHelpers::Liberator.get_all_bib_ids
VoyagerHelpers::SyncFu.bib_ids_to_file(dump_file.path)
VoyagerHelpers::SyncFu.bibs_with_holdings_to_file(dump_file.path)
VoyagerHelpers::SyncFu.recap_barcodes_since(timestamp)

