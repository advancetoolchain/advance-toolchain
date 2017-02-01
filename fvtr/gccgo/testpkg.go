/* Copyright 2017 IBM Corporation
*
*  Licensed under the Apache License, Version 2.0 (the "License");
*  you may not use this file except in compliance with the License.
*  You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
*  Unless required by applicable law or agreed to in writing, software
*  distributed under the License is distributed on an "AS IS" BASIS,
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*  See the License for the specific language governing permissions and
*  limitations under the License.
*/

package main

import (
	"fmt"
	"os"
	"math"
	"time"
	"sort"
	"regexp"
)

func main() {
	fmt.Println("Hello!")

        var time = time.Now()
	var timepat = ".*20..-..-.. ..:..:.. .*"
	var testresult = "PASS"
	match, err := regexp.MatchString(timepat, time.String())
	if match {
		fmt.Println("Error in time string", err.Error(), " fail")
		testresult = "FAIL"
	} else {
		fmt.Println("time looks good")
	}
	fmt.Println("time: ", time)

	var mysqrt = math.Sqrt(1369)

	host, err := os.Hostname()
	pid := os.Getpid()

	vals := []int{12, 21, 2, 73, 37,}
	exp := []int{73, 37, 21, 12, 2,}

	sort.Sort(sort.Reverse(sort.IntSlice(vals)))
	for i := 0; i < len(vals); i++ {
		if vals[i] != exp[i] {
			fmt.Println("Error in sorted list", i, vals[i], exp[i], " fail")
			testresult = "FAIL"
		}
	}

	if mysqrt != 37 {
		fmt.Println("Error in sqrt: fail")
		testresult = "FAIL"
	} else {
		fmt.Println("sqrt is correct")
	}
	if err == nil {
		fmt.Println("host is: ", host)
	} else {
		fmt.Println("Error with hostname: ", host, err.Error(), " fail")
		testresult = "FAIL"
	}
	if pid == 0 {
		fmt.Println("Error with pid: fail")
		testresult = "FAIL"
	}
	fmt.Println("Test result: ", testresult)
}
