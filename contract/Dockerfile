# Use the official Hyperledger Fabric chaincode environment image
FROM hyperledger/fabric-ccenv:latest

# Set up the Go environment for building the chaincode
WORKDIR /chaincode

COPY . .

RUN go build -o /chaincode

CMD ["/chaincode"]
