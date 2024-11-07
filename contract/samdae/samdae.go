package main

// import
import (
	"encoding/json"
	"fmt"
	"log"
	"time"
	"github.com/golang/protobuf/ptypes"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// 체인코드 객체정의
type SmartContract struct {
	contractapi.Contract
}

// Coffee, Sale 구조체정의
type Coffee struct {
	ID		 			string		`json:"coffee_id"`
	Name				string		`json:"coffee_name"`
	PreferenceCount		int			`json:"preference_count"`
	RatedUsers			[]string	`json:"rated_users,omitempty" metadata:"rated_users,optional"`
}


type Sale struct {
	SaleID				string		`json:"sale_id"`
	UserID				string 		`json:"user_id"`
	CoffeeId			string		`json:"coffee_id"`
	Preference			string		`json:"preference"`
	Status				string		`json:"status"` //sold, rated, compensated
}

// 이력조회 구조체 정의
type HistoryQueryResult struct {
	Record    	*Coffee    	`json:"record"`
	TxId    	string    	`json:"txId"`
	Timestamp 	time.Time 	`json:"timestamp"`
	IsDelete  	bool      	`json:"isDelete"`
}

type PreferenceResult struct {
	CoffeeName 		string	`json:"coffee_name"`
	PreferenceCount int 	`json:"count"`
}

// StateExists 매서드 구현
func (s *SmartContract) StateExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	stateJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	return stateJSON != nil, nil
}

// AddCoffee
func(s *SmartContract) AddCoffee(ctx contractapi.TransactionContextInterface, cid string, cname string) error {
	exists, err := s.StateExists(ctx, cid)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("the coffee %s already exists", cid)
	}

	coffee := Coffee{
		ID:					cid,
		Name:				cname,
		PreferenceCount:	0,
	}

	coffeeJSON, err := json.Marshal(coffee)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(cid, coffeeJSON)

}

// Purchase
func(s *SmartContract) PurchaseCoffee(ctx contractapi.TransactionContextInterface, sid string, uid string, cid string) error {
	exists, err := s.StateExists(ctx, sid)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("the sale id %s already exists", sid)
	}

	exists, err = s.StateExists(ctx, cid)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("the coffee id %s does not exist", cid)
	}

	sale := Sale{
		SaleID:					sid,
		UserID:					uid,
		CoffeeId:				cid,
		Preference:				"",
		Status:					"sold",
	}

	saleJSON, err := json.Marshal(sale)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(sid, saleJSON)

}

// Rate Register
func(s *SmartContract) RegisterRate(ctx contractapi.TransactionContextInterface, sid string, preference string) error {

	// sale update
	sale, err := s.QueryPurchase(ctx, sid)
	if err != nil {
		return err
	}
	// 세일 스테이트에 대한 검증
	if sale.Status != "sold" {
		return fmt.Errorf("The sale record is not in state SOLD")
	}
	// 선호도 커피에 대한 검증
	exists, err := s.StateExists(ctx, preference)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("the coffee id %s does not exist", sid)
	}

	sale.Preference = preference
	sale.Status = "rated"
	saleJSON, err := json.Marshal(sale)
	if err != nil {
		return err
	}

	// coffee preference update
	coffee, err := s.QueryCoffee(ctx, preference)
	if err != nil {
		return err
	}

	coffee.PreferenceCount ++
	coffee.RatedUsers = append(coffee.RatedUsers, sale.UserID)
	coffeeJSON, err := json.Marshal(coffee)
	if err != nil {
		return err
	}

	err = ctx.GetStub().PutState(sid, saleJSON)
	if err != nil {
		return err
	}
	err = ctx.GetStub().PutState(preference, coffeeJSON)
	if err != nil {
		return err
	}

	return nil
	 
}

// Finalize
func(s *SmartContract) Settle(ctx contractapi.TransactionContextInterface, cid string) error {
	// 삼대커피에 선호도에 따른 보상

	// 커피 선호도 초기화
	return fmt.Errorf("not yet");
}

// QueryCoffee
func(s *SmartContract) QueryCoffee(ctx contractapi.TransactionContextInterface, cid string) (*Coffee, error) {
	coffeeJSON, err := ctx.GetStub().GetState(cid)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if coffeeJSON == nil {
		return nil, fmt.Errorf("the coffee %s does not exist", cid)
	}

	var coffee = new(Coffee)
	err = json.Unmarshal(coffeeJSON, coffee)
	if err != nil {
		return nil, err
	}

	return coffee, nil
}

func(s *SmartContract) QueryPurchase(ctx contractapi.TransactionContextInterface, sid string) (*Sale, error) {
	saleJSON, err := ctx.GetStub().GetState(sid)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if saleJSON == nil {
		return nil, fmt.Errorf("the sale %s does not exist", sid)
	}

	var sale Sale
	err = json.Unmarshal(saleJSON, &sale)
	if err != nil {
		return nil, err
	}

	return &sale, nil
}


// QueryPreference
func(s *SmartContract) QueryPreference(ctx contractapi.TransactionContextInterface) ([]PreferenceResult, error) {
	// 전체 커피리스트 읽기

	// 상위 3개 선호도 커피이름과 카운드수 배열 만들기
	return nil, fmt.Errorf("not yet");
}

// HistoryCoffee
func (t *SmartContract) GetHistory(ctx contractapi.TransactionContextInterface, cid string) ([]HistoryQueryResult, error) {
	log.Printf("GetHistory: ID %v", cid)

	resultsIterator, err := ctx.GetStub().GetHistoryForKey(cid)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var records []HistoryQueryResult
	for resultsIterator.HasNext() {
		response, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var coffee Coffee
		if len(response.Value) > 0 {
			err = json.Unmarshal(response.Value, &coffee)
			if err != nil {
				return nil, err
			}
		} else {
			coffee = Coffee{
				ID: cid,
			}
		}

		timestamp, err := ptypes.Timestamp(response.Timestamp)
		if err != nil {
			return nil, err
		}

		record := HistoryQueryResult{
			TxId:      response.TxId,
			Timestamp: timestamp,
			Record:    &coffee,
			IsDelete:  response.IsDelete,
		}
		records = append(records, record)
	}

	return records, nil
}

// main
func main() {
	coffeeChaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		log.Panicf("Error creating samdae coffee chaincode: %v", err)
	}

	if err := coffeeChaincode.Start(); err != nil {
		log.Panicf("Error starting samdae coffee chaincode: %v", err)
	}
}