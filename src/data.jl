module Data
    using Downloads
    using XLSX
    using Unitful
    ASTMG_173 = XLSX.readxlsx("./src/data/reference_data/astmg_173.xlsx")

    S13360_50um_Silicon = XLSX.readxlsx("./src/data/detectors/sipm/S13360-50um-Silicon.xlsx")
    S13720_25um_Silicon = XLSX.readxlsx("./src/data/detectors/sipm/S13720-25um-Silicon.xlsx")
    S14160_10um_Silicon = XLSX.readxlsx("./src/data/detectors/sipm/S14160-10um-Silicon.xlsx")
    S14420_50um_Borosilicate_Glass = XLSX.readxlsx("./src/data/detectors/sipm/S14420-50um-Borosilicate_Glass.xlsx")

    S14645_Series = XLSX.readxlsx("./src/data/detectors/apd/S14645-Series.xlsx")

    # Bandpass Filters
    Thorlabs_FL905_10 = XLSX.readxlsx("./src/data/optical_filters/FL905-10.xlsx")
    Thorlabs_FB1550_40 = XLSX.readxlsx("./src/data/optical_filters/FB1550-40.xlsx")

    # ND filters
    Thorlabs_NE01B = XLSX.readxlsx("./src/data/optical_filters/NE01B.xlsx")
end # end modules Data
