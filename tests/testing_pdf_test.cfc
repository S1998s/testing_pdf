component extends="testbox.system.BaseSpec" {

    function run() {
        describe("PDF Form Tests", function() {
writeDump(server);
            it("should read form fields", function() {
                pdfPath = "D:\download\generated_acroform_____sam1.pdf";
                pdfForm = pdfPath;
                cfpdfform(action="read", source=pdfForm, result="stFormFields");
                expect(stFormFields).toBeStruct();
            });

            it("should read form field value in XML format", function() {
                pdfPath = "D:\download\generated_acroform_____sam1.pdf";
                pdfForm = pdfPath;
                cfpdfform(action="read", source=pdfForm, xmlData="myXMLData", result="stFormFields");
                expect(myXMLData).toBeStruct();
            });
            it("should read form field value and export in FDF format", function() {
                pdfPath = "D:\download\generated_acroform_____sam1.pdf";
                pdfForm = pdfPath;
                cfpdfform(action="read", source=pdfForm, fdfData="populated-pdf-form.fdf");
            });

            it("should populate form fields", function() {
                pdfPath = "D:\download\generated_acroform_____sam1.pdf";
                pdfForm = pdfPath;
                cfpdfform(action="populate", source=pdfForm, destination="D:\download\populated-pdf-form1.pdf", overwrite=true) {
                    cfpdfformparam(name="Name", value="CF Mitrah");
                    cfpdfformparam(name="Date", value="MitrahSoft");
                }
            });

            it("should populate and remove form fields", function() {
                pdfPath = "D:\download\generated_acroform_____sam1.pdf";
                pdfForm = pdfPath;
                cfpdfform(action="populate", source=pdfForm, destination="D:\download\populated-pdf-form2.pdf", flatten=true, overwrite=true) {
                    cfpdfformparam(name="Name", value="CF Mitrah");
                    cfpdfformparam(name="Date", value="MitrahSoft");
                }
            });

            // it("should populate and write to browser", function() {
            //     pdfPath = "D:\download\generated_acroform_____sam1.pdf";
            //     pdfForm = pdfPath;
            //     cfpdfform(action="populate", source=pdfForm) {
            //         cfpdfformparam(name="Name", value="CF Mitrah");
            //         cfpdfformparam(name="Date", value="MitrahSoft");
            //     }
            // });

            it("should populate form field value from XMLData", function() {
                pdfPath = "D:\download\generated_acroform_____sam1.pdf";
                pdfForm = pdfPath;
                cfpdfform(action="populate", source=pdfForm, XMLData="D:\download\ilovepdf2-PDF_to_XML\test1.xml", destination="D:\download\populated-pdf-form4.pdf", overwrite=true, flatten=true);
            });

            it("should populate form field value from FDF file", function() {
                pdfPath = "D:\download\generated_acroform_____sam1.pdf";
                pdfForm = pdfPath;
                cfpdfform(action="populate", source=pdfForm, fdfData="D:\download\sam_info_res.fdf", destination="D:\download\populated-pdf-form3.pdf", overwrite=true);
            });

            it("should support Unicode using embedded font", function() {
                pdfPath = "D:\download\generated_acroform_____sam1.pdf";
                pdfForm = pdfPath;
                cfpdfform(action="populate", source=pdfForm, destination="D:\download\embeddedfont.pdf", font="D:\download\arial\ARIAL.TTF", fontsize="10", overwrite=true) {
                    cfpdfformparam(name="Name", value="CF Mitrāh");
                    cfpdfformparam(name="Date", value="MitrāhSoft");
                }
            });

        });
    }
}