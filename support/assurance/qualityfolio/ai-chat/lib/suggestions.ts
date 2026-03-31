// lib/suggestions.ts

export type Suggestion = {
  prompt: string;
  title: string;
  description?: string;
};

export const SUGGESTIONS: Suggestion[] = [
  {
    prompt: "Can you provide me the Cycle History run for this month?",
    title: "Monthly Cycle History",
    description: "View the history of cycle runs for the current month",
  },
  {
    prompt: "Which assignee has the highest number of passed test cases in this project?",
    title: "Top Performer",
    description: "Find the assignee with the most passed test cases",
  },
  {
    prompt: "Can you summarize the current QA health of this project using the pass rate, fail rate, and defect counts shown on the dashboard?",
    title: "QA Health Summary",
    description: "Overall summary of metrics, failures, and defects",
  },
  {
    prompt: "Can you identify the weakest area in this project’s QA dashboard and recommend the top three actions to improve it quickly?",
    title: "Weakest Area Analysis",
    description: "Identify gaps and get recommendations for improvement",
  },
  {
    prompt: "Which assignee appears to be handling the more critical QA issues in this project?",
    title: "Critical Issue Handler",
    description: "Identify who is managing high-priority problems",
  }
];