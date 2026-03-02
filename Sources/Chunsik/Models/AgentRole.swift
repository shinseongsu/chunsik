import Foundation

enum AgentRole: String, Codable, CaseIterable {
    case pm
    case backend
    case frontend
    case qa
    case custom

    var displayName: String {
        switch self {
        case .pm: return "PM"
        case .backend: return "백엔드"
        case .frontend: return "프론트엔드"
        case .qa: return "QA"
        case .custom: return "커스텀"
        }
    }

    var defaultSystemPrompt: String {
        switch self {
        case .pm:
            return """
            당신은 프로젝트 매니저입니다. 사용자의 요구사항을 분석하고 백엔드와 프론트엔드 스펙을 JSON 형식으로 출력합니다.
            반드시 아래 JSON 형식으로만 응답하세요. JSON 외의 텍스트는 포함하지 마세요.
            ```json
            {
              "projectName": "프로젝트명",
              "summary": "요약",
              "backendSpec": {
                "title": "백엔드 작업 제목",
                "description": "상세 설명",
                "requirements": ["요구사항1", "요구사항2"],
                "acceptanceCriteria": ["기준1", "기준2"]
              },
              "frontendSpec": {
                "title": "프론트엔드 작업 제목",
                "description": "상세 설명",
                "requirements": ["요구사항1", "요구사항2"],
                "acceptanceCriteria": ["기준1", "기준2"]
              }
            }
            ```
            """
        case .backend:
            return "당신은 백엔드 개발자입니다. PM이 작성한 백엔드 스펙을 기반으로 API 설계, 데이터베이스 스키마, 서버 로직을 구현합니다."
        case .frontend:
            return "당신은 프론트엔드 개발자입니다. PM이 작성한 프론트엔드 스펙을 기반으로 UI 컴포넌트, 화면 설계, 사용자 인터랙션을 구현합니다."
        case .qa:
            return "당신은 QA 엔지니어입니다. 백엔드와 프론트엔드 결과물을 리뷰하고, 잠재적 문제점을 찾아내며, 통합 테스트 계획과 품질 보고서를 작성합니다."
        case .custom:
            return ""
        }
    }
}
