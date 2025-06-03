package main

import (
	"fmt"
	"encoding/json"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for interacting with the ledger
type SmartContract struct {
	contractapi.Contract
}

// Asset struct to hold asset data
type Asset struct {
	ID            string  `json:"ID"`
	Name	      string  `json:"name"`
	GreenIndex    string  `json:"greenIndex"`
	Owner         string  `json:"owner"`
}

// CreateAsset creates a new asset
func (s *SmartContract) CreateAsset(ctx contractapi.TransactionContextInterface, ID string, name string, greenIndex string, owner string) error {
	asset := Asset{
		ID:            ID,
		Name:          name,
		GreenIndex:    greenIndex,
		Owner:         owner,
	}

	assetJSON, err := json.Marshal(asset)
	if err != nil {
		return fmt.Errorf("failed to marshal asset: %v", err)
	}

	return ctx.GetStub().PutState(ID, assetJSON)
}

// GetAllAssets returns all assets
func (s *SmartContract) GetAllAssets(ctx contractapi.TransactionContextInterface) ([]Asset, error) {
	queryResults, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}

	var assets []Asset
	for queryResults.HasNext() {
		result, err := queryResults.Next()
		if err != nil {
			return nil, err
		}

		var asset Asset
		err = json.Unmarshal(result.Value, &asset)
		if err != nil {
			return nil, err
		}
		assets = append(assets, asset)
	}

	return assets, nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		fmt.Printf("Error creating chaincode: %s", err.Error())
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting chaincode: %s", err.Error())
	}
}
