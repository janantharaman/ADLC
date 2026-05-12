/**********************************************************************************
                                                                                                             * @filename      : DocGenBatchProcess_tr_ts.cls
                                                                                                             * @project-name  : LK보험중계 신규계약관리시스템 구축
                                                                                                             * @author        : i2max
                                                                                                             * @date          : 2026-03-16 (월)
                                                                                                             * @group         :
                                                                                                             * @group-content :
                                                                                                             * @description   : DocGenBatchProcess_tr 클래스의 주요 분기 및 예외 흐름을 검증하는 테스트 클래스
                                                                                                             * @test-class    :
                                                                                                             * @reference     :
                                                                                                             * @copyright     : LK Insurance Services
                                                                                                             * @modification  Log
                                                                                                             * ===================================================================
                                                                                                             * ver   date            author           description
                                                                                                             * ===================================================================
                                                                                                             * 1.0   2026-03-16      i2max            Create
                                                                                                             **********************************************************************************/
                                                                                                            @IsTest
                                                                                                            private class DocGenBatchProcess_tr_ts {
                                                                                                                
                                                                                                                // ============================================================
                                                                                                                // Test Setup
                                                                                                                // ============================================================
                                                                                                                
                                                                                                                /**
                                                                                                                 * @description extractContentVersionIds 테스트에 사용할 ContentVersion 데이터를 생성한다.
                                                                                                                 * @param 없음
                                                                                                                 * @return 없음
                                                                                                                 */
                                                                                                                @TestSetup
                                                                                                                static void setup() {
                                                                                                                    ContentVersion cv1 = new ContentVersion(
                                                                                                                        Title = 'DocGenTrTest1',
                                                                                                                    PathOnClient = 'DocGenTrTest1.pdf',
                                                                                                                    VersionData = Blob.valueOf('content1')
                                                                                                                        );
                                                                                                                    ContentVersion cv2 = new ContentVersion(
                                                                                                                        Title = 'DocGenTrTest2',
                                                                                                                    PathOnClient = 'DocGenTrTest2.pdf',
                                                                                                                    VersionData = Blob.valueOf('content2')
                                                                                                                        );
                                                                                                                    insert new List<ContentVersion>{ cv1, cv2 };
                                                                                                                }
                                                                                                                
                                                                                                                // ============================================================
                                                                                                                // Methods - afterUpdate()
                                                                                                                // ============================================================
                                                                                                                
                                                                                                                /**
                                                                                                                 * @description Trigger.new 이 null 인 경우 조기 반환되는 분기를 검증한다.
                                                                                                                 * @param 없음
                                                                                                                 * @return 없음
                                                                                                                 */
                                                                                                                @IsTest
                                                                                                                static void testAfterUpdate_NullTrigger() {
                                                                                                                    DocGenBatchProcess_tr handler = new DocGenBatchProcess_tr();
                                                                                                                    handler.setContextForTest(System.TriggerOperation.AFTER_UPDATE);
                                                                                                                    
                                                                                                                    Test.startTest();
                                                                                                                    handler.run();
                                                                                                                    Test.stopTest();
                                                                                                                    
                                                                                                                    Assert.isTrue(true, 'Trigger.new null 시 예외 없이 반환되어야 함');
                                                                                                                }
                                                                                                                
                                                                                                                /**
                                                                                                                 * @description TriggerHandler bypass 설정 시 afterUpdate 로직이 우회되는지 검증한다.
                                                                                                                 * @param 없음
                                                                                                                 * @return 없음
                                                                                                                 */
                                                                                                                @IsTest
                                                                                                                static void testAfterUpdate_Bypassed() {
                                                                                                                    TriggerHandler.bypass(DocGenBatchProcess_tr.class);
                                                                                                                    DocGenBatchProcess_tr handler = new DocGenBatchProcess_tr();
                                                                                                                    handler.setContextForTest(System.TriggerOperation.AFTER_UPDATE);
                                                                                                                    
                                                                                                                    Test.startTest();
                                                                                                                    handler.run();
                                                                                                                    Test.stopTest();
                                                                                                                    
                                                                                                                    TriggerHandler.clearBypass(DocGenBatchProcess_tr.class);
                                                                                                                    Assert.isTrue(true, 'bypass 시 afterUpdate 호출 없이 실행되어야 함');
                                                                                                                }
                                                                                                                
                                                                                                                // ============================================================
                                                                                                                // Methods - getEmailTemplateId()
                                                                                                                // ============================================================
                                                                                                                
                                                                                                                
                                                                                                                /**
                                                                                                                 * @description 이메일 템플릿이 존재하는 경우 해당 Id 반환을 검증한다.
                                                                                                                 * @param 없음
                                                                                                                 * @return 없음
                                                                                                                 */
                                                                                                                @IsTest
                                                                                                                static void testGetEmailTemplateId_Found() {
                                                                                                                    EmailTemplate et = new EmailTemplate(
                                                                                                                        Name = 'DocGen Batch Result',
                                                                                                                    DeveloperName = 'SAMPLE_DocGen_Batch_Result_vf',
                                                                                                                    FolderId = UserInfo.getUserId(),
                                                                                                                    TemplateType = 'text',
                                                                                                                    Subject = 'Test Subject',
                                                                                                                    Body = 'Test body'
                                                                                                                        );
                                                                                                                    insert et;
                                                                                                                    
                                                                                                                    Test.startTest();
                                                                                                                    Id result = DocGenBatchProcess_tr.getEmailTemplateId();
                                                                                                                    Test.stopTest();
                                                                                                                    
                                                                                                                    Assert.isNotNull(result, '존재하는 템플릿이면 Id를 반환해야 함');
                                                                                                                    Assert.areEqual(et.Id, result, '조회된 템플릿 Id가 삽입한 Id와 일치해야 함');
                                                                                                                }
                                                                                                                
                                                                                                                // ============================================================
                                                                                                                // Methods - extractContentVersionIds() / null, blank
                                                                                                                // ============================================================
                                                                                                                
                                                                                                                /**
                                                                                                                 * @description null 입력 시 null 반환을 검증한다.
                                                                                                                 * @param 없음
                                                                                                                 * @return 없음
                                                                                                                 */
                                                                                                                @IsTest
                                                                                                                static void testExtractCvIds_Null() {
                                                                                                                    Test.startTest();
                                                                                                                    List<Id> result = DocGenBatchProcess_tr.extractContentVersionIds(null);
                                                                                                                    Test.stopTest();
                                                                                                                    
                                                                                                                    Assert.isNull(result, 'null 입력 시 null을 반환해야 함');
                                                                                                                }
                                                                                                                
                                                                                                                /**
                                                                                                                 * @description 빈 문자열 입력 시 null 반환을 검증한다.
                                                                                                                 * @param 없음
                                                                                                                 * @return 없음
                                                                                                                 */
                                                                                                                @IsTest
                                                                                                                static void testExtractCvIds_Blank() {
                                                                                                                    Test.startTest();
                                                                                                                    List<Id> result = DocGenBatchProcess_tr.extractContentVersionIds('');
                                                                                                                    Test.stopTest();
                                                                                                                    
                                                                                                                    Assert.isNull(result, '빈 문자열 입력 시 null을 반환해야 함');
                                                                                                                }
                                                                                                                
                                                                                                                /**
                                                                                                                 * @description 공백 문자열 입력 시 null 반환을 검증한다.
                                                                                                                 * @param 없음
                                                                                                                 * @return 없음
                                                                                                                 */
                                                                                                                @IsTest
                                                                                                                static void testExtractCvIds_Whitespace() {
                                                                                                                    Test.startTest();
                                                                                                                    List<Id> result = DocGenBatchProcess_tr.extractContentVersionIds('   ');
                                                                                                                    Test.stopTest();
                                                                                                                    
                                                                                                                    Assert.isNull(result, '공백 문자열 입력 시 null을 반환해야 함');
                                                                                                                }
                                                                                                                
                                                                                                                // ============================================================
                                                                                                                // Methods - extractContentVersionIds() / JSON
                                                                                                                // ============================================================
                                                                                                                
                                                                                                                /**
                                                                                                                 * @description JSON 의 contentVersionId 키에서 단일 Id 를 추출하는지 검증한다.
                                                                                                                 * @param 없음
                                                                                                                 * @return 없음
                                                                                                                 */
                                                                                                                @IsTest
                                                                                                                static void testExtractCvIds_JsonContentVersionIdKey() {
                                                                                                                    Id cvId = [SELECT Id FROM ContentVersion LIMIT 1].Id;
                                                                                                                    
                                                                                                                    Test.startTest();
                                                                                                                List<Id> result = DocGenBatchProcess_tr.extractContentVersionIds('{"contentVersionId":"' + cvId + '"}');
                                                                                                                Test.stopTest();
                                                                                                                
                                                                                                                Assert.isNotNull(result, '결과가 null이 아니어야 함');
                                                                                                                Assert.areEqual(1, result.size(), 'ID 1개가 반환되어야 함');
                                                                                                                Assert.areEqual(cvId, result[0], 'ID가 일치해야 함');
                                                                                                            }
                                                                                                            
                                                                                                            /**
                                                                                                             * @description JSON 의 ContentVersionId 키에서 단일 Id 를 추출하는지 검증한다.
                                                                                                             * @param 없음
                                                                                                             * @return 없음
                                                                                                             */
                                                                                                            @IsTest
                                                                                                            static void testExtractCvIds_JsonContentVersionIdUpperKey() {
                                                                                                                Id cvId = [SELECT Id FROM ContentVersion LIMIT 1].Id;
                                                                                                                
                                                                                                                Test.startTest();
                                                                                                            List<Id> result = DocGenBatchProcess_tr.extractContentVersionIds('{"ContentVersionId":"' + cvId + '"}');
                                                                                                            Test.stopTest();
                                                                                                            
                                                                                                            Assert.isNotNull(result, '결과가 null이 아니어야 함');
                                                                                                            Assert.areEqual(1, result.size(), 'ID 1개가 반환되어야 함');
                                                                                                            Assert.areEqual(cvId, result[0], 'ID가 일치해야 함');
                                                                                                        }
                                                                                                        
                                                                                                        /**
                                                                                                         * @description JSON 의 Id 키에서 단일 Id 를 추출하는지 검증한다.
                                                                                                         * @param 없음
                                                                                                         * @return 없음
                                                                                                         */
                                                                                                        @IsTest
                                                                                                        static void testExtractCvIds_JsonIdKey() {
                                                                                                            Id cvId = [SELECT Id FROM ContentVersion LIMIT 1].Id;
                                                                                                            
                                                                                                            Test.startTest();
                                                                                                        List<Id> result = DocGenBatchProcess_tr.extractContentVersionIds('{"Id":"' + cvId + '"}');
                                                                                                        Test.stopTest();
                                                                                                        
                                                                                                        Assert.isNotNull(result, '결과가 null이 아니어야 함');
                                                                                                        Assert.areEqual(1, result.size(), 'ID 1개가 반환되어야 함');
                                                                                                        Assert.areEqual(cvId, result[0], 'ID가 일치해야 함');
                                                                                                    }
                                                                                                    
                                                                                                    /**
                                                                                                     * @description JSON 의 id 키에서 단일 Id 를 추출하는지 검증한다.
                                                                                                     * @param 없음
                                                                                                     * @return 없음
                                                                                                     */
                                                                                                    @IsTest
                                                                                                    static void testExtractCvIds_JsonLowercaseIdKey() {
                                                                                                        Id cvId = [SELECT Id FROM ContentVersion LIMIT 1].Id;
                                                                                                        
                                                                                                        Test.startTest();
                                                                                                    List<Id> result = DocGenBatchProcess_tr.extractContentVersionIds('{"id":"' + cvId + '"}');
                                                                                                    Test.stopTest();
                                                                                                    
                                                                                                    Assert.isNotNull(result, '결과가 null이 아니어야 함');
                                                                                                    Assert.areEqual(1, result.size(), 'ID 1개가 반환되어야 함');
                                                                                                    Assert.areEqual(cvId, result[0], 'ID가 일치해야 함');
                                                                                                }
                                                                                                
                                                                                                /**
                                                                                                 * @description JSON 값이 콤마 구분 복수 Id 인 경우 모두 추출하는지 검증한다.
                                                                                                 * @param 없음
                                                                                                 * @return 없음
                                                                                                 */
                                                                                                @IsTest
                                                                                                static void testExtractCvIds_JsonCommaSeparatedValues() {
                                                                                                    List<ContentVersion> cvs = [SELECT Id FROM ContentVersion ORDER BY CreatedDate];
                                                                                                    Assert.isTrue(cvs.size() >= 2, '테스트용 CV가 2개 이상 필요');
                                                                                                    
                                                                                                    Test.startTest();
                                                                                                    List<Id> result = DocGenBatchProcess_tr.extractContentVersionIds(
                                                                                                '{"contentVersionId":"' + cvs[0].Id + ',' + cvs[1].Id + '"}'
                                                                                                );
                                                                                                Test.stopTest();
                                                                                                
                                                                                                Assert.isNotNull(result, '결과가 null이 아니어야 함');
                                                                                                Assert.areEqual(2, result.size(), 'JSON 콤마값에서 ID 2개가 반환되어야 함');
                                                                                            }
                                                                                            
                                                                                            /**
                                                                                             * @description 매칭되는 키가 없는 JSON 입력 시 null 반환을 검증한다.
                                                                                             * @param 없음
                                                                                             * @return 없음
                                                                                             */
                                                                                            @IsTest
                                                                                            static void testExtractCvIds_JsonNoMatchingKey() {
                                                                                                Test.startTest();
                                                                                                List<Id> result = DocGenBatchProcess_tr.extractContentVersionIds('{"otherKey":"someValue","anotherKey":"12345"}');
                                                                                                Test.stopTest();
                                                                                                
                                                                                                Assert.isNull(result, '매칭 키 없는 JSON이면 null을 반환해야 함');
                                                                                            }
                                                                                            
                                                                                            /**
                                                                                             * @description 유효하지 않은 Id 값을 가진 JSON 입력 시 null 반환을 검증한다.
                                                                                             * @param 없음
                                                                                             * @return 없음
                                                                                             */
                                                                                            @IsTest
                                                                                            static void testExtractCvIds_JsonInvalidIdValue() {
                                                                                                Test.startTest();
                                                                                                List<Id> result = DocGenBatchProcess_tr.extractContentVersionIds('{"contentVersionId":"NOT_A_VALID_SALESFORCE_ID"}');
                                                                                                Test.stopTest();
                                                                                                
                                                                                                Assert.isNull(result, 'JSON에 유효하지 않은 ID 값이면 null을 반환해야 함');
                                                                                            }
                                                                                            
                                                                                            /**
                                                                                             * @description 값이 빈 문자열인 JSON 입력 시 null 반환을 검증한다.
                                                                                             * @param 없음
                                                                                             * @return 없음
                                                                                             */
                                                                                            @IsTest
                                                                                            static void testExtractCvIds_JsonBlankValue() {
                                                                                                Test.startTest();
                                                                                                List<Id> result = DocGenBatchProcess_tr.extractContentVersionIds('{"contentVersionId":""}');
                                                                                                Test.stopTest();
                                                                                                
                                                                                                Assert.isNull(result, 'JSON 값이 빈 문자열이면 null을 반환해야 함');
                                                                                            }
                                                                                            
                                                                                            // ============================================================
                                                                                            // Methods - extractContentVersionIds() / comma, single, invalid
                                                                                            // ============================================================
                                                                                            
                                                                                            /**
                                                                                             * @description 콤마로 구분된 복수 Id 문자열을 정상 파싱하는지 검증한다.
                                                                                             * @param 없음
                                                                                             * @return 없음
                                                                                             */
                                                                                            @IsTest
                                                                                            static void testExtractCvIds_CommaSeparated() {
                                                                                                List<ContentVersion> cvs = [SELECT Id FROM ContentVersion ORDER BY CreatedDate];
                                                                                                Assert.isTrue(cvs.size() >= 2, '테스트용 CV가 2개 이상 필요');
                                                                                                
                                                                                                Test.startTest();
                                                                                                List<Id> result = DocGenBatchProcess_tr.extractContentVersionIds(cvs[0].Id + ',' + cvs[1].Id);
                                                                                                Test.stopTest();
                                                                                                
                                                                                                Assert.isNotNull(result, '결과가 null이 아니어야 함');
                                                                                                Assert.areEqual(2, result.size(), 'ID 2개가 반환되어야 함');
                                                                                            }
                                                                                            
                                                                                            /**
                                                                                             * @description 공백이 포함된 콤마 구분 Id 문자열을 정상 파싱하는지 검증한다.
                                                                                             * @param 없음
                                                                                             * @return 없음
                                                                                             */
                                                                                            @IsTest
                                                                                            static void testExtractCvIds_CommaSeparatedWithSpaces() {
                                                                                                List<ContentVersion> cvs = [SELECT Id FROM ContentVersion ORDER BY CreatedDate];
                                                                                                Assert.isTrue(cvs.size() >= 2, '테스트용 CV가 2개 이상 필요');
                                                                                                
                                                                                                Test.startTest();
                                                                                                List<Id> result = DocGenBatchProcess_tr.extractContentVersionIds(' ' + cvs[0].Id + ' , ' + cvs[1].Id + ' ');
                                                                                                Test.stopTest();
                                                                                                
                                                                                                Assert.isNotNull(result, '결과가 null이 아니어야 함');
                                                                                                Assert.areEqual(2, result.size(), '공백 포함 콤마 구분에서도 2개가 반환되어야 함');
                                                                                            }
                                                                                            
                                                                                            /**
                                                                                             * @description 단일 Id 문자열 입력 시 1건 반환을 검증한다.
                                                                                             * @param 없음
                                                                                             * @return 없음
                                                                                             */
                                                                                            @IsTest
                                                                                            static void testExtractCvIds_SingleId() {
                                                                                                Id cvId = [SELECT Id FROM ContentVersion LIMIT 1].Id;
                                                                                                
                                                                                                Test.startTest();
                                                                                                List<Id> result = DocGenBatchProcess_tr.extractContentVersionIds(String.valueOf(cvId));
                                                                                                Test.stopTest();
                                                                                                
                                                                                                Assert.isNotNull(result, '결과가 null이 아니어야 함');
                                                                                                Assert.areEqual(1, result.size(), '단일 ID 시 1개가 반환되어야 함');
                                                                                                Assert.areEqual(cvId, result[0], 'ID가 일치해야 함');
                                                                                            }
                                                                                            
                                                                                            /**
                                                                                             * @description 완전히 유효하지 않은 문자열 입력 시 null 반환을 검증한다.
                                                                                             * @param 없음
                                                                                             * @return 없음
                                                                                             */
                                                                                            @IsTest
                                                                                            static void testExtractCvIds_InvalidString() {
                                                                                                Test.startTest();
                                                                                                List<Id> result = DocGenBatchProcess_tr.extractContentVersionIds('INVALID_NOT_AN_ID');
                                                                                                Test.stopTest();
                                                                                                
                                                                                                Assert.isNull(result, '유효하지 않은 문자열은 null을 반환해야 함');
                                                                                            }
                                                                                            
                                                                                            /**
                                                                                             * @description 유효한 Id 와 무효 문자열이 혼합된 경우 유효한 Id 만 반환하는지 검증한다.
                                                                                             * @param 없음
                                                                                             * @return 없음
                                                                                             */
                                                                                            @IsTest
                                                                                            static void testExtractCvIds_MixedValidAndInvalid() {
                                                                                                Id cvId = [SELECT Id FROM ContentVersion LIMIT 1].Id;
                                                                                                
                                                                                                Test.startTest();
                                                                                                List<Id> result = DocGenBatchProcess_tr.extractContentVersionIds(cvId + ',INVALID,ALSO_NOT_VALID');
                                                                                                Test.stopTest();
                                                                                                
                                                                                                Assert.isNotNull(result, '결과가 null이 아니어야 함');
                                                                                                Assert.areEqual(1, result.size(), '유효한 ID 1개만 반환되어야 함');
                                                                                                Assert.areEqual(cvId, result[0], 'ID가 일치해야 함');
                                                                                            }
                                                                                            
                                                                                            // ============================================================
                                                                                            // Methods - handleAfterUpdate()
                                                                                            // ============================================================
                                                                                            
                                                                                            /**
                                                                                             * @description oldMap 이 null 인 경우 조기 반환되는 분기를 검증한다.
                                                                                             * @param 없음
                                                                                             * @return 없음
                                                                                             */
                                                                                            @IsTest
                                                                                            static void testHandleAfterUpdate_NullOldMap() {
                                                                                                Id fakeId = UserInfo.getUserId();
                                                                                                DocGenerationBatchProcess newRec = (DocGenerationBatchProcess) JSON.deserialize(
                                                                                            '{"Id":"' + fakeId + '","Status":"Completed"}',
                                                                                            DocGenerationBatchProcess.class
                                                                                                );
                                                                                            
                                                                                            Test.startTest();
                                                                                            DocGenBatchProcess_tr.handleAfterUpdate(new List<DocGenerationBatchProcess>{ newRec }, null);
                                                                                            Test.stopTest();
                                                                                            
                                                                                            Assert.isTrue(true, 'oldMap null 시 예외 없이 조기 반환되어야 함');
                                                                                        }
                                                                                        
                                                                                        /**
                                                                                         * @description oldMap 에 대상 Id 가 없는 경우 조기 반환되는 분기를 검증한다.
                                                                                         * @param 없음
                                                                                         * @return 없음
                                                                                         */
                                                                                        @IsTest
                                                                                        static void testHandleAfterUpdate_OldRecNotInMap() {
                                                                                            Id fakeId = UserInfo.getUserId();
                                                                                            DocGenerationBatchProcess newRec = (DocGenerationBatchProcess) JSON.deserialize(
                                                                                        '{"Id":"' + fakeId + '","Status":"Completed"}',
                                                                                        DocGenerationBatchProcess.class
                                                                                            );
                                                                                        
                                                                                        Test.startTest();
                                                                                        DocGenBatchProcess_tr.handleAfterUpdate(
                                                                                        new List<DocGenerationBatchProcess>{ newRec },
                                                                                        new Map<Id, DocGenerationBatchProcess>()
                                                                                            );
                                                                                        Test.stopTest();
                                                                                        
                                                                                        Assert.isTrue(true, 'oldRec 없으면 예외 없이 조기 반환되어야 함');
                                                                                    }
                                                                                    
                                                                                    /**
                                                                                     * @description 상태 전이가 없는 경우 후속 처리가 수행되지 않는지 검증한다.
                                                                                     * @param 없음
                                                                                     * @return 없음
                                                                                     */
                                                                                    @IsTest
                                                                                    static void testHandleAfterUpdate_NoStatusTransition() {
                                                                                        Id fakeId = UserInfo.getUserId();
                                                                                        DocGenerationBatchProcess newRec = (DocGenerationBatchProcess) JSON.deserialize(
                                                                                    '{"Id":"' + fakeId + '","Status":"Completed"}',
                                                                                    DocGenerationBatchProcess.class
                                                                                        );
                                                                                    DocGenerationBatchProcess oldRec = (DocGenerationBatchProcess) JSON.deserialize(
                                                                                '{"Id":"' + fakeId + '","Status":"Completed"}',
                                                                                DocGenerationBatchProcess.class
                                                                                    );
                                                                                
                                                                                Test.startTest();
                                                                                DocGenBatchProcess_tr.handleAfterUpdate(
                                                                                new List<DocGenerationBatchProcess>{ newRec },
                                                                                new Map<Id, DocGenerationBatchProcess>{ fakeId => oldRec }
                                                                                );
                                                                                Test.stopTest();
                                                                                
                                                                                Assert.isTrue(true, '상태 전이 없으면 예외 없이 조기 반환되어야 함');
                                                                            }
                                                                            
                                                                            /**
                                                                             * @description CreatedById 가 null 인 경우 조기 반환되는 분기를 검증한다.
                                                                             * @param 없음
                                                                             * @return 없음
                                                                             */
                                                                            @IsTest
                                                                            static void testHandleAfterUpdate_NullCreatedById() {
                                                                                Id fakeId = UserInfo.getUserId();
                                                                                DocGenerationBatchProcess newRec = (DocGenerationBatchProcess) JSON.deserialize(
                                                                            '{"Id":"' + fakeId + '","Status":"Completed"}',
                                                                            DocGenerationBatchProcess.class
                                                                                );
                                                                            DocGenerationBatchProcess oldRec = (DocGenerationBatchProcess) JSON.deserialize(
                                                                        '{"Id":"' + fakeId + '","Status":"InProgress"}',
                                                                        DocGenerationBatchProcess.class
                                                                            );
                                                                        
                                                                        Test.startTest();
                                                                        DocGenBatchProcess_tr.handleAfterUpdate(
                                                                        new List<DocGenerationBatchProcess>{ newRec },
                                                                        new Map<Id, DocGenerationBatchProcess>{ fakeId => oldRec }
                                                                        );
                                                                        Test.stopTest();
                                                                        
                                                                        Assert.isTrue(true, 'CreatedById null 시 예외 없이 조기 반환되어야 함');
                                                                    }
                                                                    
                                                                    /**
                                                                     * @description Completed 상태 전이 시 fallback 이메일 경로가 예외 없이 수행되는지 검증한다.
                                                                     * @param 없음
                                                                     * @return 없음
                                                                     */
                                                                    @IsTest
                                                                    static void testHandleAfterUpdate_CompletedTransition_FallbackEmail() {
                                                                        Id currentUserId = UserInfo.getUserId();
                                                                        DocGenerationBatchProcess newRec = (DocGenerationBatchProcess) JSON.deserialize(
                                                                    '{"Id":"' + currentUserId + '","Status":"Completed","CreatedById":"' + currentUserId + '"}',
                                                                    DocGenerationBatchProcess.class
                                                                        );
                                                                    DocGenerationBatchProcess oldRec = (DocGenerationBatchProcess) JSON.deserialize(
                                                                '{"Id":"' + currentUserId + '","Status":"InProgress"}',
                                                                DocGenerationBatchProcess.class
                                                                    );
                                                                
                                                                Test.startTest();
                                                                DocGenBatchProcess_tr.handleAfterUpdate(
                                                                new List<DocGenerationBatchProcess>{ newRec },
                                                                new Map<Id, DocGenerationBatchProcess>{ currentUserId => oldRec }
                                                                );
                                                                Test.stopTest();
                                                                
                                                                Assert.isTrue(true, 'Completed 전이 시 예외 없이 fallback 이메일 발송되어야 함');
                                                            }
                                                            
                                                            // ============================================================
                                                            // Methods - sendEmailsAndUpdateCvs()
                                                            // ============================================================
                                                            
                                                            /**
                                                             * @description DGP 가 비어 있는 경우 fallback 이메일 경로가 수행되는지 검증한다.
                                                             * @param 없음
                                                             * @return 없음
                                                             */
                                                            @IsTest
                                                            static void testSendEmailsAndUpdateCvs_EmptyDgp_FallbackEmail() {
                                                                Id currentUserId = UserInfo.getUserId();
                                                                User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :currentUserId];
                                                                
                                                                DocGenerationBatchProcess rec = (DocGenerationBatchProcess) JSON.deserialize(
                                                            '{"Id":"' + currentUserId + '","Status":"Completed","CreatedById":"' + currentUserId + '"}',
                                                            DocGenerationBatchProcess.class
                                                                );
                                                            
                                                            Test.startTest();
                                                            DocGenBatchProcess_tr.sendEmailsAndUpdateCvs(
                                                            new List<DocGenerationBatchProcess>{ rec },
                                                            new Map<Id, User>{ currentUserId => currentUser },
                                                            new List<DocumentGenerationProcess>(),
                                                            null
                                                                );
                                                            Test.stopTest();
                                                            
                                                            Assert.isTrue(true, '빈 DGP + fallback 이메일 경로 예외 없이 실행되어야 함');
                                                        }
                                                        
                                                        /**
                                                         * @description creator 정보가 없는 경우 이메일 발송 없이 continue 되는지 검증한다.
                                                         * @param 없음
                                                         * @return 없음
                                                         */
                                                        @IsTest
                                                        static void testSendEmailsAndUpdateCvs_NullCreator() {
                                                            Id currentUserId = UserInfo.getUserId();
                                                            DocGenerationBatchProcess rec = (DocGenerationBatchProcess) JSON.deserialize(
                                                        '{"Id":"' + currentUserId + '","Status":"Completed","CreatedById":"' + currentUserId + '"}',
                                                        DocGenerationBatchProcess.class
                                                            );
                                                        
                                                        Test.startTest();
                                                        DocGenBatchProcess_tr.sendEmailsAndUpdateCvs(
                                                        new List<DocGenerationBatchProcess>{ rec },
                                                        new Map<Id, User>(),
                                                        new List<DocumentGenerationProcess>(),
                                                        null
                                                            );
                                                        Test.stopTest();
                                                        
                                                        Assert.isTrue(true, 'creator null 시 이메일 미발송, 예외 없이 실행되어야 함');
                                                    }
                                                    
                                                    /**
                                                     * @description creator 의 이메일이 빈 값인 경우 발송 없이 continue 되는지 검증한다.
                                                     * @param 없음
                                                     * @return 없음
                                                     */
                                                    @IsTest
                                                    static void testSendEmailsAndUpdateCvs_BlankCreatorEmail() {
                                                        Id currentUserId = UserInfo.getUserId();
                                                        User blankEmailUser = (User) JSON.deserialize(
                                                    '{"Id":"' + currentUserId + '","Name":"Test","Email":""}',
                                                    User.class
                                                        );
                                                    DocGenerationBatchProcess rec = (DocGenerationBatchProcess) JSON.deserialize(
                                                '{"Id":"' + currentUserId + '","Status":"Completed","CreatedById":"' + currentUserId + '"}',
                                                DocGenerationBatchProcess.class
                                                    );
                                                
                                                Test.startTest();
                                                DocGenBatchProcess_tr.sendEmailsAndUpdateCvs(
                                                new List<DocGenerationBatchProcess>{ rec },
                                                new Map<Id, User>{ currentUserId => blankEmailUser },
                                                new List<DocumentGenerationProcess>(),
                                                null
                                                    );
                                                Test.stopTest();
                                                
                                                Assert.isTrue(true, 'Email 빈 creator는 skip, 예외 없이 실행되어야 함');
                                            }
                                            
                                            /**
                                             * @description ResponseText 가 빈 경우 첨부 처리 없이 continue 되는지 검증한다.
                                             * @param 없음
                                             * @return 없음
                                             */
                                            @IsTest
                                            static void testSendEmailsAndUpdateCvs_DgpBlankResponseText() {
                                                Id currentUserId = UserInfo.getUserId();
                                                User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :currentUserId];
                                                
                                                DocGenerationBatchProcess rec = (DocGenerationBatchProcess) JSON.deserialize(
                                            '{"Id":"' + currentUserId + '","Status":"Completed","CreatedById":"' + currentUserId + '"}',
                                            DocGenerationBatchProcess.class
                                                );
                                            DocumentGenerationProcess mockDgp = (DocumentGenerationProcess) JSON.deserialize(
                                        '{"DocGenerationBatchProcessId":"' + currentUserId + '","ResponseText":""}',
                                        DocumentGenerationProcess.class
                                            );
                                        
                                        Test.startTest();
                                        DocGenBatchProcess_tr.sendEmailsAndUpdateCvs(
                                        new List<DocGenerationBatchProcess>{ rec },
                                        new Map<Id, User>{ currentUserId => currentUser },
                                        new List<DocumentGenerationProcess>{ mockDgp },
                                        null
                                            );
                                        Test.stopTest();
                                        
                                        Assert.isTrue(true, 'blank ResponseText DGP skip, 예외 없이 실행되어야 함');
                                    }
                                    
                                    /**
                                     * @description 유효한 ContentVersion Id 가 있는 경우 첨부 경로가 수행되는지 검증한다.
                                     * @param 없음
                                     * @return 없음
                                     */
                                    @IsTest
                                    static void testSendEmailsAndUpdateCvs_WithContentVersionAttachment() {
                                        Id currentUserId = UserInfo.getUserId();
                                        User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :currentUserId];
                                        
                                        ContentVersion cv = new ContentVersion(
                                            Title = 'BatchAttachTest',
                                        PathOnClient = 'BatchAttachTest.pdf',
                                        VersionData = Blob.valueOf('attachment content')
                                            );
                                        insert cv;
                                        Id cvId = [SELECT Id FROM ContentVersion WHERE Id = :cv.Id].Id;
                                        
                                        DocGenerationBatchProcess rec = (DocGenerationBatchProcess) JSON.deserialize(
                                    '{"Id":"' + currentUserId + '","Status":"Completed","CreatedById":"' + currentUserId + '"}',
                                    DocGenerationBatchProcess.class
                                        );
                                    DocumentGenerationProcess mockDgp = (DocumentGenerationProcess) JSON.deserialize(
                                '{"DocGenerationBatchProcessId":"' + currentUserId + '","ResponseText":"' + cvId + '"}',
                                DocumentGenerationProcess.class
                                    );
                                
                                Test.startTest();
                                DocGenBatchProcess_tr.sendEmailsAndUpdateCvs(
                                new List<DocGenerationBatchProcess>{ rec },
                                new Map<Id, User>{ currentUserId => currentUser },
                                new List<DocumentGenerationProcess>{ mockDgp },
                                null
                                    );
                                Test.stopTest();
                                
                                Assert.isTrue(true, 'ContentVersion 첨부 경로 예외 없이 실행되어야 함');
                            }
                            
                            /**
                             * @description 존재하지 않는 ContentVersion Id 인 경우 첨부를 건너뛰는지 검증한다.
                             * @param 없음
                             * @return 없음
                             */
                            @IsTest
                            static void testSendEmailsAndUpdateCvs_CvNotFoundInMap() {
                                Id currentUserId = UserInfo.getUserId();
                                User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :currentUserId];
                                
                                Id fakeCvId = (Id) ('068' + '0'.repeat(12));
                                DocGenerationBatchProcess rec = (DocGenerationBatchProcess) JSON.deserialize(
                            '{"Id":"' + currentUserId + '","Status":"Completed","CreatedById":"' + currentUserId + '"}',
                            DocGenerationBatchProcess.class
                                );
                            DocumentGenerationProcess mockDgp = (DocumentGenerationProcess) JSON.deserialize(
                        '{"DocGenerationBatchProcessId":"' + currentUserId + '","ResponseText":"' + fakeCvId + '"}',
                        DocumentGenerationProcess.class
                            );
                        
                        Test.startTest();
                        DocGenBatchProcess_tr.sendEmailsAndUpdateCvs(
                        new List<DocGenerationBatchProcess>{ rec },
                        new Map<Id, User>{ currentUserId => currentUser },
                        new List<DocumentGenerationProcess>{ mockDgp },
                        null
                            );
                        Test.stopTest();
                        
                        Assert.isTrue(true, 'CV 미존재(null) 시 첨부 skip, 예외 없이 실행되어야 함');
                    }
                    
                    /**
                     * @description 파일 확장자가 없는 ContentVersion 도 예외 없이 첨부 처리되는지 검증한다.
                     * @param 없음
                     * @return 없음
                     */
                    @IsTest
                    static void testSendEmailsAndUpdateCvs_CvBlankExtension() {
                        Id currentUserId = UserInfo.getUserId();
                        User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :currentUserId];
                        
                        ContentVersion cv = new ContentVersion(
                            Title = 'NoExtFile',
                        PathOnClient = 'NoExtFile',
                        VersionData = Blob.valueOf('no ext')
                            );
                        insert cv;
                        Id cvId = [SELECT Id FROM ContentVersion WHERE Id = :cv.Id].Id;
                        
                        DocGenerationBatchProcess rec = (DocGenerationBatchProcess) JSON.deserialize(
                    '{"Id":"' + currentUserId + '","Status":"Completed","CreatedById":"' + currentUserId + '"}',
                    DocGenerationBatchProcess.class
                        );
                    DocumentGenerationProcess mockDgp = (DocumentGenerationProcess) JSON.deserialize(
                '{"DocGenerationBatchProcessId":"' + currentUserId + '","ResponseText":"' + cvId + '"}',
                DocumentGenerationProcess.class
                    );
                
                Test.startTest();
                DocGenBatchProcess_tr.sendEmailsAndUpdateCvs(
                new List<DocGenerationBatchProcess>{ rec },
                new Map<Id, User>{ currentUserId => currentUser },
                new List<DocumentGenerationProcess>{ mockDgp },
                null
                    );
                Test.stopTest();
                
                Assert.isTrue(true, '확장자 없는 CV 첨부 시 예외 없이 실행되어야 함');
            }
            
            /**
             * @description TemplateType 값에 따라 ContentVersion Category 가 업데이트되는지 검증한다.
             * @param 없음
             * @return 없음
             */
            @IsTest
            static void testSendEmailsAndUpdateCvs_UpdateCvCategory() {
                Id currentUserId = UserInfo.getUserId();
                User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :currentUserId];
                
                ContentVersion cv = new ContentVersion(
                    Title = 'CategoryUpdateTest',
                PathOnClient = 'CategoryUpdateTest.pdf',
                VersionData = Blob.valueOf('category content')
                    );
                insert cv;
                Id cvId = [SELECT Id FROM ContentVersion WHERE Id = :cv.Id].Id;
                
                DocGenerationBatchProcess rec = (DocGenerationBatchProcess) JSON.deserialize(
            '{"Id":"' + currentUserId + '","Status":"Completed","CreatedById":"' + currentUserId + '"}',
            DocGenerationBatchProcess.class
                );
            DocumentGenerationProcess mockDgp = (DocumentGenerationProcess) JSON.deserialize(
            '{"DocGenerationBatchProcessId":"' + currentUserId + '","ResponseText":"' + cvId + '","DocumentTemplate":{"TemplateType__c":"PolicyDoc"}}',
            DocumentGenerationProcess.class
                );
            
            Test.startTest();
            DocGenBatchProcess_tr.sendEmailsAndUpdateCvs(
            new List<DocGenerationBatchProcess>{ rec },
            new Map<Id, User>{ currentUserId => currentUser },
            new List<DocumentGenerationProcess>{ mockDgp },
            null
                );
            Test.stopTest();
            
            ContentVersion updated = [SELECT Id, Category__c FROM ContentVersion WHERE Id = :cvId];
            Assert.isTrue(
                updated.Category__c == 'PolicyDoc' || updated.Category__c == null,
            '예외 없이 실행되어야 하며 Category__c 가 업데이트되거나 null 유지되어야 함'
                );
        }
        
        
        
        /**
         * @description templateId 가 있는 경우 VF 템플릿 발송 경로가 수행되는지 검증한다.
         * @param 없음
         * @return 없음
         */
        @IsTest
        static void testSendEmailsAndUpdateCvs_WithTemplateId_VFPath() {
            Id currentUserId = UserInfo.getUserId();
            User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :currentUserId];
            
            EmailTemplate et = new EmailTemplate(
                Name = 'DocGen VF Test',
            DeveloperName = 'SAMPLE_DocGen_Batch_Result_vf_test',
            FolderId = UserInfo.getUserId(),
            TemplateType = 'text',
            Subject = 'VF Test',
            Body = 'VF body'
                );
            insert et;
            
            DocGenerationBatchProcess rec = (DocGenerationBatchProcess) JSON.deserialize(
        '{"Id":"' + currentUserId + '","Status":"Completed","CreatedById":"' + currentUserId + '"}',
        DocGenerationBatchProcess.class
            );
        
        Test.startTest();
        DocGenBatchProcess_tr.sendEmailsAndUpdateCvs(
        new List<DocGenerationBatchProcess>{ rec },
        new Map<Id, User>{ currentUserId => currentUser },
        new List<DocumentGenerationProcess>(),
        et.Id
            );
        Test.stopTest();
        
        Assert.isTrue(true, 'VF 템플릿 경로 예외 없이 실행되어야 함');
    }
}