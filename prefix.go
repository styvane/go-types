package types

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"fmt"

	"github.com/nu7hatch/gouuid"
)

type PrefixUUID struct {
	Prefix string
	UUID   *uuid.UUID
}

func (u *PrefixUUID) String() string {
	return u.Prefix + u.UUID.String()
}

// NewPrefixUUID creates a PrefixUUID from the prefix and string uuid. Returns
// an error if uuidstr cannot be parsed as a valid UUID
func NewPrefixUUID(caboodle string) (PrefixUUID, error) {
	if len(caboodle) < 36 {
		return PrefixUUID{}, fmt.Errorf("types: Could not parse \"%s\" as a UUID with a prefix", caboodle)
	}
	uuidPart := caboodle[len(caboodle)-36:]
	u, err := uuid.ParseHex(uuidPart)
	if err != nil {
		return PrefixUUID{}, err
	}

	return PrefixUUID{
		Prefix: caboodle[:len(caboodle)-36],
		UUID:   u,
	}, nil
}

func (pu *PrefixUUID) UnmarshalJSON(b []byte) error {
	var s string
	err := json.Unmarshal(b, &s)
	if err != nil {
		return err
	}
	p, err := NewPrefixUUID(s)
	if err != nil {
		return err
	}
	*pu = p
	return nil
}

func (pu PrefixUUID) MarshalJSON() ([]byte, error) {
	if pu.UUID == nil {
		return []byte{}, errors.New("no UUID to convert to JSON")
	}
	return json.Marshal(pu.String())
}

// Scan implements the Scanner interface. Note only the UUID gets scanned/set
// here, we can't determine the prefix from the database. `value` should be
// a [16]byte
func (pu *PrefixUUID) Scan(value interface{}) error {
	if value == nil {
		return errors.New("types: cannot scan null into a PrefixUUID")
	}
	bits, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("types: can't scan value %v into a PrefixUUID", value)
	}
	var u *uuid.UUID
	var err error
	if len(bits) == 36 {
		u, err = uuid.ParseHex(string(bits))
	} else {
		u, err = uuid.Parse(bits)
	}
	if err != nil {
		return err
	}
	pu.UUID = u
	return nil
}

// Value implements the driver.Valuer interface.
func (pu PrefixUUID) Value() (driver.Value, error) {
	// In theory we should be able to send 16 raw bytes to the database
	// and have it encoded as a UUID. However, this requires enabling
	// binary_parameters=yes on the connection string. Instead of that, just
	// pass a string to the database.
	return pu.UUID.String(), nil
}
