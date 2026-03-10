use marctk::{Field, Record};

pub trait ExtractValues<'a> {
    fn extract_field_values_by<C, E, T>(self, criteria: C, extractor: E) -> impl Iterator<Item = T>
    where
        C: Fn(&'a Field) -> bool,
        E: Fn(&'a Field) -> Option<T>;
}

impl<'a> ExtractValues<'a> for &'a Record {
    fn extract_field_values_by<C, E, T>(self, criteria: C, extractor: E) -> impl Iterator<Item = T>
    where
        C: Fn(&'a Field) -> bool,
        E: Fn(&'a Field) -> Option<T>,
    {
        self.fields().iter().filter_map(move |field| {
            if criteria(field) {
                extractor(field)
            } else {
                None
            }
        })
    }
}
