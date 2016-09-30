#' @title Request data from the Quarterly Census of Employment and Wages.
#' @description Return data from the QCEW API. This is seperate from the main BLS API and returns quarterly data
#' sliced by industry, area or size. Industry is identified by NIACS code and area is identified by FIPS code.
#' A key is not required for the QCEW API.
#' @param year These data begin in 2012 and go to the most recent complete quarter. The argument can be entered
#' as an integer or a character. The default is 2012.
#' @param qtr Quarter: This can be any integer between 1 and 4. The argument can be entered
#' as an integer or a character. The default is 1, which returns the first quarter.
#' @param slice The slice should be one of the three data slices offered by the API; "industry", "area", or "size."
#' @param sliceCode The slice codes depend on what slice you select. For example, if you select the "area" slice,
#' your \code{sliceCode} should be a FIPS code. If you select "industry," your \code{sliceCode} should be a NIACS code.
#' There are three internal data sets containing acceptable slice codes to help with selections; \code{blscrapeR::niacs}
#' contains industry codes and descriptions, \code{blscrapeR::area_titles} contains FIPS codes and area descriptions,
#' and \code{blscrapeR::size_titles} contains industry size codes. These codes can be used for the \code{sliceCode} argument.
#' @keywords bls api economics cpi unemployment inflation
#' @importFrom data.table rbindlist
#' @importFrom jsonlite toJSON
#' @importFrom httr content POST content_type_json
#' @export qcew_api
#' @seealso \url{http://data.bls.gov/cew/doc/access/csv_data_slices.htm}
#' @examples
#' 
#' \dontrun{
#' # A request for the employment levels and wages for NIACS 5112: Software Publishers.
#' dat <- qcew_api(year=2016, qtr=1, slice="industry", sliceCode=5112)
#' }
#' 
qcew_api <- function(year=2012, qtr=1, slice=NULL, sliceCode=NULL){
    if (is.null("slice") | is.null("sliceCode")){
        message("Please specify a Slice and sliceCode. See function documentation for examples.")
    }
    slice <- as.character(tolower(slice))
    sliceCode <- as.character(sliceCode)
    slice.options <- c("industry", "area", "size")
    if (!isTRUE(any(grepl(slice, slice.options)))){
        message("Please select slice as 'area', 'industry', or 'size'")
    }
    if (!is.numeric(year)){message("Please set a numeric year.")}
    if (!is.numeric(qtr)){message("Please set a numeric quarter.")}
    if (slice=="area" & is.numeric(sliceCode) & !isTRUE(sliceCode %in% blscrapeR::area_titles$area_fips)){
        message("Invalid sliceCode, please check you FIPS code.")
    }
    if (slice=="industry" & is.numeric(sliceCode) & !isTRUE(sliceCode %in% blscrapeR::niacs$industry_code)){
        message("Invalid sliceCode, please check you NIACS code.")
    } 
    if (slice=="size" & is.numeric(sliceCode) & !isTRUE(sliceCode %in% blscrapeR::size_titles$size_code)){
        message("Invalid sliceCode, please enter an integer between 0 and 9.")
    }   
    baseURL <- "http://data.bls.gov/cew/data/api/"
    url <- paste0(baseURL, year, "/", qtr, "/", slice, "/", sliceCode, ".csv")
    temp <- tempfile()
    out <- tryCatch(
        {
            message("Trying BLS servers...")
            download.file(url, temp, quiet = TRUE)
        },
        error=function(cond) {
            message(paste("URL does not seem to exist:", url))
            return(NA)
        },
        warning=function(cond) {
            message(paste("URL caused a warning:", url))
            return(NULL)
        },
        finally={
            message(paste("Processed URL:", url))
            qcewDat <- read.csv(temp, fill=TRUE, header=TRUE, sep=",", stringsAsFactors=FALSE,
                                strip.white=TRUE)
        }
    )    
    return(qcewDat)
}
