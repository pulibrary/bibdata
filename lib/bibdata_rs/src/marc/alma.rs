use marctk::{Field, Subfield};

pub struct AlmaHoldingId<'a>(pub &'a str);

impl<'a> AlmaHoldingId<'a> {
    pub fn is_valid(&self) -> bool {
        self.0.starts_with("22") && self.0.ends_with("06421")
    }
}

impl<'a> From<&'a Subfield> for AlmaHoldingId<'a> {
    fn from(subfield: &'a Subfield) -> Self {
        Self(subfield.content())
    }
}

#[derive(Default, PartialEq)]
pub enum AlmaElectronicPortfolio {
    Active,
    #[default]
    Inactive,
}

impl From<&Subfield> for AlmaElectronicPortfolio {
    fn from(subfield: &Subfield) -> Self {
        if subfield.content() == "Available" {
            Self::Active
        } else {
            Self::Inactive
        }
    }
}

impl AlmaElectronicPortfolio {
    pub fn is_valid_portfolio_id(id: &str) -> bool {
        id.starts_with("53") && id.ends_with("06421")
    }
}

pub struct InvalidPortfolioData;

impl<'a> TryFrom<&'a Field> for AlmaElectronicPortfolio {
    type Error = InvalidPortfolioData;

    fn try_from(field: &'a Field) -> Result<Self, Self::Error> {
        if field.tag() != "951" {
            return Err(InvalidPortfolioData);
        };
        field
            .first_subfield("8")
            .and_then(|id_subfield| {
                let id = id_subfield.content();
                if Self::is_valid_portfolio_id(id) {
                    field.first_subfield("a").map(Self::from)
                } else {
                    None
                }
            })
            .ok_or(InvalidPortfolioData)
    }
}
