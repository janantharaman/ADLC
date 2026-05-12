import { LightningElement } from "lwc";

export default class TempSoa extends LightningElement {
    tableColumns = [
        {
            label: "Note No.",
            name: "1"
        },
        {
            label: "Note Type",
            name: "2"
        },
        {
            label: "Note Details",
            name: "header_NoteDetails",
            columns: [
                {
                    label: "Account Name",
                    name: "3"
                },
                {
                    label: "Origin Currency",
                    name: "4"
                },
                {
                    label: "Origin Amount",
                    name: "5"
                },
                {
                    label: "Issue Date",
                    name: "6"
                },
                {
                    label: "Contact",
                    name: "7"
                },
                {
                    label: "Particular",
                    name: "8"
                },
                {
                    label: "Email",
                    name: "9"
                },
                {
                    label: "Origin Amount (Settled)",
                    name: "10"
                },
                {
                    label: "Origin Amount (Balance)",
                    name: "11"
                },
                {
                    label: "Notes Status",
                    name: "12"
                }
            ]
        },
        {
            label: "PPW Date",
            name: "header_PPWDate",
            columns: [
                {
                    label: "PPW Type",
                    name: "13"
                },
                {
                    label: "No of Installment",
                    name: "14"
                },
                {
                    label: "Install(%)",
                    name: "15",
                    collapsible: true
                },
                {
                    label: "PPW Date",
                    name: "16"
                }
            ]
        },
        {
            label: "Placement",
            name: "header_Placement",
            columns: [
                {
                    label: "LK Ref. No.",
                    name: "17"
                },
                {
                    label: "Cedant Ref. No.",
                    name: "18",
                    collapsible: true
                },
                {
                    label: "Cedant",
                    name: "19",
                    collapsible: true
                },
                {
                    label: "Cedant Facility Name",
                    name: "20",
                    collapsible: true
                },
                {
                    label: "Insured",
                    name: "21"
                },
                {
                    label: "Inception Date",
                    name: "22"
                },
                {
                    label: "Expiration Date",
                    name: "23"
                },
                {
                    label: "LOB",
                    name: "24",
                    collapsible: true
                },
                {
                    label: "Type",
                    name: "25",
                    collapsible: true
                }
            ]
        },
        {
            label: "Claim",
            name: "header_Claim",
            columns: [
                {
                    label: "Parent Claim No.",
                    name: "26",
                    collapsible: true
                },
                {
                    label: "Cedant Claim No.",
                    name: "27",
                    collapsible: true
                },
                {
                    label: "Date of Loss",
                    name: "28"
                },
                {
                    label: "Location of Loss",
                    name: "29"
                },
                {
                    label: "SOC Seq.",
                    name: "30"
                },
                {
                    label: "Child Claim No.",
                    name: "31",
                    collapsible: true
                }
            ]
        },
        {
            label: "Account Contact",
            name: "32"
        },
        {
            label: "Email to Account Contact",
            name: "33"
        },
        {
            label: "Note (D/C, SOC)",
            name: "34"
        },
        {
            label: "Cover Note",
            name: "35"
        },
        {
            label: "Closing Slip",
            name: "36"
        },
        {
            label: "SOC from Cedant",
            name: "37"
        }
    ];

    tableData = [];
}