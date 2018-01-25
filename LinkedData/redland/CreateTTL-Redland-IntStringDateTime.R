###############################################################################
# FILE: CreateTTL-Redland-IntStringDateTime.R
# DESC: Create a TTL file using the redland package
#       Creates: xsd:string, xsd:int, xsd:dateTime 
# REQ : redland
# REF : https://cran.r-project.org/web/packages/redland/README.html
# SRC : 
# IN  : internal
# OUT : 
# NOTE: 
# TODO: 
###############################################################################
library(redland)
setwd("<YOUR PATH HERE>")

# World is the redland mechanism for scoping models
world <- new("World")

# Storage provides a mechanism to store models; in-memory hashes are convenient for small models
storage <- new("Storage", world, "hashes", name="", options="hash-type='memory'")

# A model is a set of Statements, and is associated with a particular Storage instance
model <- new("Model", world=world, storage, options="")

# Various prefixes for use in addStatement fnt
DC   <- "http://purl.org/dc/elements/1.1/"
RDFS <- "http://www.w3.org/2000/01/rdf-schema#"
FOO  <- "http://www.foo.bar/test/"
XSD  <- "http://www.w3.org/2001/XMLSchema#"

# title
addStatement(model, 
  new("Statement", world=world,                                                    
      subject   = "http://ropensci.org/", 
      predicate = paste0(DC, "title"), 
      object    = "ROpenSci")
)
# Language
addStatement(model, 
  new("Statement", world=world, 
     subject   = "http://ropensci.org/", 
     predicate = paste0(DC, "language"), 
     object    = "en")
)
# License
addStatement(model, 
  new("Statement", world=world, 
     subject   = "http://ropensci.org/", 
     predicate = paste0(DC, "license"), 
     object    = "https://creativecommons.org/licenses/by/2.0/")
)
# Literal xsd:string
addStatement(model, 
  new("Statement", world=world, 
      subject   = paste0(FOO,"SupinePosition"), 
      predicate = paste0(RDFS, "label"), 
      object    = "Assume Supine Body Position",
          objectType   = "literal", 
          datatype_uri = paste0(XSD,"string")
    )
)

# Literal xsd:int.  Note: cannot use 'integer'
addStatement(model, 
  new("Statement", world=world, 
      subject   = paste0(FOO,"PERSON_1"), 
      predicate = paste0(FOO, "ageYears"), 
      object    = "23",
          objectType   = "literal", 
          datatype_uri = paste0(XSD,"int")
    )
)

# Literal xsd:dateTime
addStatement(model, 
  new("Statement", world=world, 
      subject   = paste0(FOO,"PERSON_1"), 
      predicate = paste0(FOO, "collectedOn"), 
      object    = "2001-10-26T21:32:52",
          objectType   = "literal", 
          datatype_uri = paste0(XSD,"dateTime")
    )
)

#Serialize the model to a TTL file
serializer <- new("Serializer", world, name="turtle", mimeType="text/turtle")
status <- setNameSpace(serializer, world, namespace="http://purl.org/dc/elements/1.1/", prefix="dc")  
status <- setNameSpace(serializer, world, namespace="http://www.foo.bar/test/", prefix="foo")  
status <- setNameSpace(serializer, world, namespace="http://www.w3.org/2000/01/rdf-schema#", prefix="rdfs")  
status <- setNameSpace(serializer, world, namespace="http://www.w3.org/2001/XMLSchema#", prefix="xsd")

filePath <- 'CreateTTL-Redland-IntStringDateTime.TTL'
status <- serializeToFile(serializer, world, model, filePath)